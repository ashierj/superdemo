<script>
import { GlEmptyState, GlSkeletonLoader } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert } from '~/alert';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_CREATED } from '~/lib/utils/http_status';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { InternalEvents } from '~/tracking';
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import FeedbackBanner from 'ee/analytics/dashboards/components/feedback_banner.vue';
import {
  buildDefaultDashboardFilters,
  getDashboardConfig,
  updateApolloCache,
} from 'ee/vue_shared/components/customizable_dashboard/utils';
import { saveCustomDashboard } from 'ee/analytics/analytics_dashboards/api/dashboards_api';
import { BUILT_IN_VALUE_STREAM_DASHBOARD } from 'ee/analytics/dashboards/constants';
import { hydrateLegacyYamlConfiguration } from 'ee/analytics/dashboards/yaml_utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  FILE_ALREADY_EXISTS_SERVER_RESPONSE,
  NEW_DASHBOARD,
  EVENT_LABEL_CREATED_DASHBOARD,
  EVENT_LABEL_EDITED_DASHBOARD,
  EVENT_LABEL_VIEWED_CUSTOM_DASHBOARD,
} from '../constants';
import getCustomizableDashboardQuery from '../graphql/queries/get_customizable_dashboard.query.graphql';
import getAvailableVisualizations from '../graphql/queries/get_all_customizable_visualizations.query.graphql';

const HIDE_DASHBOARD_FILTERS = [BUILT_IN_VALUE_STREAM_DASHBOARD];

export default {
  name: 'AnalyticsDashboard',
  components: {
    CustomizableDashboard,
    FeedbackBanner,
    GlEmptyState,
    GlSkeletonLoader,
  },
  mixins: [InternalEvents.mixin(), glFeatureFlagsMixin()],
  inject: {
    customDashboardsProject: {
      type: Object,
      default: null,
    },
    namespaceFullPath: {
      type: String,
    },
    namespaceId: {
      type: String,
    },
    isProject: {
      type: Boolean,
    },
    isGroup: {
      type: Boolean,
    },
    dashboardEmptyStateIllustrationPath: {
      type: String,
    },
    breadcrumbState: {
      type: Object,
    },
    vsdAvailableVisualizations: {
      type: Array,
      default: [],
    },
  },
  async beforeRouteLeave(to, from, next) {
    const confirmed = await this.$refs.dashboard.confirmDiscardIfChanged();

    if (!confirmed) return;

    next();
  },
  props: {
    isNewDashboard: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      initialDashboard: null,
      showEmptyState: false,
      availableVisualizations: {
        loading: true,
        hasError: false,
        visualizations: [],
      },
      defaultFilters: buildDefaultDashboardFilters(window.location.search),
      isSaving: false,
      titleValidationError: null,
      backUrl: this.$router.resolve('/').href,
      changesSaved: false,
      alert: null,
      hasDashboardError: false,
      vsdYamlDashboard: null,
    };
  },
  computed: {
    currentDashboard() {
      return this.vsdYamlDashboard || this.initialDashboard;
    },
    currentDashboardIsVsd() {
      return this.currentDashboard?.slug === BUILT_IN_VALUE_STREAM_DASHBOARD;
    },
    showDashboardFilters() {
      return !HIDE_DASHBOARD_FILTERS.includes(this.currentDashboard?.slug);
    },
    shouldFetchLegacyYamlConfiguration() {
      // NOTE: If there is no pointer project configured, we won't have a YAML file to fetch.
      // We only need to perform this check when viewing the VSD (Value streams dashboard)
      return (
        this.$route?.params.slug === BUILT_IN_VALUE_STREAM_DASHBOARD &&
        this.customDashboardsProject?.id
      );
    },
  },
  watch: {
    initialDashboard(initialDashboard) {
      if (initialDashboard?.userDefined) {
        this.trackEvent(EVENT_LABEL_VIEWED_CUSTOM_DASHBOARD);
      }
    },
  },
  async created() {
    if (this.shouldFetchLegacyYamlConfiguration) {
      this.vsdYamlDashboard = await hydrateLegacyYamlConfiguration(
        this.customDashboardsProject.id,
        this.vsdAvailableVisualizations,
      );
      return;
    }

    if (this.isNewDashboard) {
      this.initialDashboard = this.createNewDashboard();
    }
  },
  beforeDestroy() {
    this.alert?.dismiss();

    // Clear the breadcrumb name when we leave this component so it doesn't
    // flash the wrong name when a user views a different dashboard
    this.breadcrumbState.updateName('');
  },
  apollo: {
    initialDashboard: {
      query: getCustomizableDashboardQuery,
      variables() {
        return {
          fullPath: this.namespaceFullPath,
          slug: this.$route?.params.slug,
          isProject: this.isProject,
          isGroup: this.isGroup,
        };
      },
      skip() {
        return this.isNewDashboard;
      },
      update(data) {
        const namespaceData = this.isProject ? data.project : data.group;
        const [dashboard] = namespaceData?.customizableDashboards?.nodes || [];

        if (!dashboard) {
          this.showEmptyState = true;
          return null;
        }

        return {
          ...dashboard,
          panels: dashboard.panels?.nodes || [],
        };
      },
      result() {
        this.breadcrumbState.updateName(this.initialDashboard?.title || '');
      },
      error(error) {
        this.showError({
          error,
          capture: true,
          message: s__(
            'Analytics|Something went wrong while loading the dashboard. Refresh the page to try again or see %{linkStart}troubleshooting documentation%{linkEnd}.',
          ),
          messageLinks: {
            link: helpPagePath('user/analytics/analytics_dashboards', {
              anchor: '#troubleshooting',
            }),
          },
        });
        this.hasDashboardError = true;
      },
    },
    availableVisualizations: {
      query: getAvailableVisualizations,
      variables() {
        return {
          fullPath: this.namespaceFullPath,
          isProject: this.isProject,
          isGroup: this.isGroup,
        };
      },
      skip() {
        return !this.initialDashboard || !this.initialDashboard?.userDefined;
      },
      update(data) {
        const namespaceData = this.isProject ? data.project : data.group;
        const visualizations = namespaceData?.customizableDashboardVisualizations?.nodes || [];
        return {
          loading: false,
          hasError: false,
          visualizations,
        };
      },
      error(error) {
        this.availableVisualizations = {
          loading: false,
          hasError: true,
          visualizations: [],
        };

        Sentry.captureException(error);
      },
    },
  },
  methods: {
    createNewDashboard() {
      return NEW_DASHBOARD();
    },
    async saveDashboard(dashboardSlug, dashboard) {
      this.validateDashboardTitle(dashboard.title, true);
      if (this.titleValidationError) {
        return;
      }

      try {
        this.changesSaved = false;
        this.isSaving = true;
        const saveResult = await saveCustomDashboard({
          dashboardSlug,
          dashboardConfig: getDashboardConfig(dashboard),
          projectInfo: this.customDashboardsProject,
          isNewFile: this.isNewDashboard,
        });

        if (saveResult?.status === HTTP_STATUS_CREATED) {
          this.alert?.dismiss();

          this.$toast.show(s__('Analytics|Dashboard was saved successfully'));

          if (this.isNewDashboard) {
            this.trackEvent(EVENT_LABEL_CREATED_DASHBOARD);
          } else {
            this.trackEvent(EVENT_LABEL_EDITED_DASHBOARD);
          }

          const apolloClient = this.$apollo.getClient();
          updateApolloCache({
            apolloClient,
            slug: dashboardSlug,
            dashboard,
            fullPath: this.namespaceFullPath,
            isProject: this.isProject,
            isGroup: this.isGroup,
          });

          if (this.isNewDashboard) {
            // We redirect now to the new route
            this.$router.push({
              name: 'dashboard-detail',
              params: { slug: dashboardSlug },
            });
          }

          this.changesSaved = true;
        } else {
          throw new Error(`Bad save dashboard response. Status:${saveResult?.status}`);
        }
      } catch (error) {
        const { message = '' } = error?.response?.data || {};

        if (message === FILE_ALREADY_EXISTS_SERVER_RESPONSE) {
          this.titleValidationError = s__('Analytics|A dashboard with that name already exists.');
        } else if (error.response?.status === HTTP_STATUS_BAD_REQUEST) {
          // We can assume bad request errors are a result of user error.
          // We don't need to capture these errors and can render the message to the user.
          this.showError({ error, capture: false, message: error.response?.data?.message });
        } else {
          this.showError({ error, capture: true });
        }
      } finally {
        this.isSaving = false;
      }
    },
    showError({ error, capture, message, messageLinks }) {
      this.alert = createAlert({
        message: message || s__('Analytics|Error while saving dashboard'),
        messageLinks,
        error,
        captureError: capture,
      });
    },
    validateDashboardTitle(newTitle, submitting) {
      if (this.titleValidationError !== null || submitting) {
        this.titleValidationError = newTitle?.length > 0 ? '' : __('This field is required.');
      }
    },
  },
};
</script>

<template>
  <div>
    <template v-if="currentDashboard">
      <feedback-banner v-if="currentDashboardIsVsd" />
      <customizable-dashboard
        ref="dashboard"
        :initial-dashboard="currentDashboard"
        :available-visualizations="availableVisualizations"
        :default-filters="defaultFilters"
        :is-saving="isSaving"
        :date-range-limit="0"
        :sync-url-filters="!isNewDashboard"
        :is-new-dashboard="isNewDashboard"
        :show-date-range-filter="showDashboardFilters"
        :show-anon-users-filter="showDashboardFilters"
        :changes-saved="changesSaved"
        :title-validation-error="titleValidationError"
        @save="saveDashboard"
        @title-input="validateDashboardTitle"
      />
    </template>
    <gl-empty-state
      v-else-if="showEmptyState"
      :svg-path="dashboardEmptyStateIllustrationPath"
      :svg-height="null"
      :title="s__('Analytics|Dashboard not found')"
      :description="s__('Analytics|No dashboard matches the specified URL path.')"
      :primary-button-text="s__('Analytics|View available dashboards')"
      :primary-button-link="backUrl"
    />
    <div v-else-if="!hasDashboardError" class="gl-mt-7">
      <gl-skeleton-loader />
    </div>
  </div>
</template>

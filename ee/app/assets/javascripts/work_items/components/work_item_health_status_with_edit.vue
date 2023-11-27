<script>
import { GlForm, GlCollapsibleListbox, GlButton, GlLoadingIcon } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import IssueHealthStatus from 'ee/related_items_tree/components/issue_health_status.vue';
import {
  HEALTH_STATUS_I18N_HEALTH_STATUS,
  HEALTH_STATUS_I18N_NO_STATUS,
  HEALTH_STATUS_I18N_NONE,
  healthStatusDropdownOptions,
} from 'ee/sidebar/constants';
import {
  I18N_WORK_ITEM_ERROR_UPDATING,
  sprintfWorkItem,
  TRACKING_CATEGORY_SHOW,
} from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import Tracking from '~/tracking';

export default {
  HEALTH_STATUS_I18N_HEALTH_STATUS,
  HEALTH_STATUS_I18N_NO_STATUS,
  HEALTH_STATUS_I18N_NONE,
  healthStatusDropdownOptions,
  components: {
    GlForm,
    GlCollapsibleListbox,
    GlButton,
    GlLoadingIcon,
    IssueHealthStatus,
  },
  mixins: [Tracking.mixin()],
  inject: ['hasIssuableHealthStatusFeature'],
  props: {
    healthStatus: {
      type: String,
      required: false,
      default: null,
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isEditing: false,
      updateInProgress: false,
    };
  },
  computed: {
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_health_status',
        property: `type_${this.workItemType}`,
      };
    },
    dropdownItems() {
      const emptyItem = {
        text: this.$options.HEALTH_STATUS_I18N_NO_STATUS,
        value: 'empty',
      };
      return [emptyItem, ...healthStatusDropdownOptions];
    },
    selectedHealthStatus() {
      return this.healthStatus || 'empty';
    },
  },
  methods: {
    isSelected(healthStatus) {
      return this.healthStatus === healthStatus;
    },
    onDropdownHide() {
      this.isEditing = false;
    },
    updateHealthStatus(healthStatus) {
      if (!this.canUpdate) {
        return;
      }

      this.track('updated_health_status');

      this.updateInProgress = true;

      this.$apollo
        .mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              healthStatusWidget: {
                healthStatus: healthStatus === 'empty' ? null : healthStatus,
              },
            },
          },
        })
        .then(({ data }) => {
          if (data.workItemUpdate.errors.length) {
            throw new Error(data.workItemUpdate.errors.join('\n'));
          }
        })
        .catch((error) => {
          const msg = sprintfWorkItem(I18N_WORK_ITEM_ERROR_UPDATING, this.workItemType);
          this.$emit('error', msg);
          Sentry.captureException(error);
        })
        .finally(() => {
          this.updateInProgress = false;
        });
    },
  },
};
</script>

<template>
  <div v-if="hasIssuableHealthStatusFeature">
    <div class="gl-display-flex gl-align-items-center">
      <!-- hide header when editing, since we then have a form label. Keep it reachable for screenreader nav  -->
      <h3 :class="{ 'gl-sr-only': isEditing }" class="gl-mb-0! gl-heading-scale-5">
        {{ $options.HEALTH_STATUS_I18N_HEALTH_STATUS }}
      </h3>
      <gl-loading-icon v-if="updateInProgress" size="sm" inline class="gl-ml-2 gl-my-0" />
      <gl-button
        v-if="canUpdate && !isEditing"
        data-testid="edit-health-status"
        category="tertiary"
        size="small"
        class="gl-ml-auto gl-mr-2"
        :disabled="updateInProgress"
        @click="isEditing = true"
        >{{ __('Edit') }}</gl-button
      >
    </div>
    <gl-form v-if="isEditing">
      <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
        <label :for="$options.inputId" class="gl-mb-0">{{
          $options.HEALTH_STATUS_I18N_HEALTH_STATUS
        }}</label>
        <gl-button
          data-testid="apply-health-status"
          category="tertiary"
          size="small"
          class="gl-mr-2"
          @click="isEditing = false"
          >{{ __('Apply') }}</gl-button
        >
      </div>
      <div class="gl-pr-2 gl-relative">
        <gl-collapsible-listbox
          :items="dropdownItems"
          :disabled="!canUpdate"
          :loading="updateInProgress"
          :selected="selectedHealthStatus"
          start-opened
          block
          data-testid="work-item-health-status-dropdown"
          @hidden="onDropdownHide"
          @select="updateHealthStatus"
        />
      </div>
    </gl-form>
    <issue-health-status
      v-else-if="healthStatus"
      data-testid="work-item-health-status-value"
      :health-status="healthStatus"
    />
    <span
      v-else
      data-testid="work-item-health-status-none"
      class="gl-text-secondary gl-display-inline-block"
      >{{ $options.HEALTH_STATUS_I18N_NONE }}</span
    >
  </div>
</template>

<script>
import { GlAlert, GlLink, GlSkeletonLoader, GlSprintf } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';

import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { nMonthsBefore } from '~/lib/utils/datetime/date_calculation_utility';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import { projectHasProductAnalyticsEnabled } from '../utils';
import getGroupProductAnalyticsUsage from '../graphql/queries/get_group_product_analytics_usage.query.graphql';
import { getCurrentMonth, mapMonthlyTotals } from './utils';

export default {
  name: 'ProductAnalyticsGroupUsage',
  components: {
    GlAlert,
    GlAreaChart,
    GlLink,
    GlSkeletonLoader,
    GlSprintf,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    namespacePath: {
      type: String,
    },
  },
  data() {
    return {
      error: null,
      projectsUsageData: null,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.projectsUsageData.loading;
    },
    chartData() {
      return [
        {
          name: s__('ProductAnalytics|Analytics events by month'),
          data: this.projectsUsageData,
        },
      ];
    },
  },
  apollo: {
    projectsUsageData: {
      query: getGroupProductAnalyticsUsage,
      variables() {
        return {
          namespacePath: this.namespacePath,
          monthSelection: this.getMonthsToQuery(),
        };
      },
      update(data) {
        const projects = data.group.projects.nodes.filter(projectHasProductAnalyticsEnabled);

        if (projects.length === 0) {
          this.$emit('no-projects');
          return [];
        }

        return mapMonthlyTotals(projects);
      },
      error(error) {
        this.error = error;
        Sentry.captureException(error);
      },
    },
  },
  methods: {
    getMonthsToQuery() {
      // 12 months data will cause backend performance issues for some large groups. So we can toggle
      // this when needed until performance is improved in https://gitlab.com/gitlab-org/gitlab/-/issues/430865
      const ONE_YEAR = 12;
      const TWO_MONTHS = 2;
      const numMonthsDataToFetch = this.glFeatures.productAnalyticsUsageQuotaAnnualData
        ? ONE_YEAR
        : TWO_MONTHS;

      const currentMonth = getCurrentMonth();
      return Array.from({ length: numMonthsDataToFetch }).map((_, index) => {
        const date = nMonthsBefore(currentMonth, index);

        // note: JS `getMonth()` is 0 based, so add 1
        return { year: date.getFullYear(), month: date.getMonth() + 1 };
      });
    },
  },
  CHART_OPTIONS: {
    yAxis: {
      name: s__('ProductAnalytics|Events'),
    },
    xAxis: {
      name: s__('ProductAnalytics|Month'),
      type: 'category',
    },
  },
  LEARN_MORE_URL: helpPagePath('/user/product_analytics/index', {
    anchor: 'product-analytics-usage-quota',
  }),
};
</script>
<template>
  <section class="gl-mt-5 gl-mb-7">
    <h2 class="gl-font-lg">{{ s__('ProductAnalytics|Usage by month') }}</h2>
    <p>
      <gl-sprintf
        :message="
          s__(
            'ProductAnalytics|Product analytics usage is calculated based on the total number of events received from projects within the group. %{linkStart}Learn more%{linkEnd}.',
          )
        "
      >
        <template #link="{ content }">
          <gl-link
            :href="$options.LEARN_MORE_URL"
            data-testid="product-analytics-usage-quota-learn-more"
            >{{ content }}</gl-link
          >
        </template>
      </gl-sprintf>
    </p>
    <gl-alert v-if="error" variant="danger" :dismissible="false">
      {{
        s__(
          'ProductAnalytics|Something went wrong while loading product analytics usage data. Refresh the page to try again.',
        )
      }}
    </gl-alert>
    <gl-skeleton-loader v-else-if="isLoading" :lines="3" />
    <template v-else>
      <gl-area-chart :data="chartData" :option="$options.CHART_OPTIONS" />
    </template>
  </section>
</template>

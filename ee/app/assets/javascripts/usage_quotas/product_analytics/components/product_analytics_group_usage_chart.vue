<script>
import { GlAlert, GlLink, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  dateAtFirstDayOfMonth,
  nMonthsBefore,
} from '~/lib/utils/datetime/date_calculation_utility';
import { formatDate } from '~/lib/utils/datetime/date_format_utility';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import getGroupCurrentAndPrevProductAnalyticsUsageQuery from '../graphql/queries/get_group_current_and_prev_product_analytics_usage.query.graphql';

export default {
  name: 'ProductAnalyticsGroupUsageChart',
  components: {
    GlAlert,
    GlAreaChart,
    GlLink,
    GlSkeletonLoader,
    GlSprintf,
  },
  inject: {
    namespacePath: {
      type: String,
    },
  },
  data() {
    const currentMonth = dateAtFirstDayOfMonth(new Date());
    const previousMonth = nMonthsBefore(currentMonth, 1);

    return {
      error: null,
      projectsUsageData: null,
      currentMonth,
      previousMonth,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.projectsUsageData.loading;
    },
    chartData() {
      return [
        {
          name: s__('Analytics|Analytics events by month'),
          data: this.projectsUsageData.map(([date, usageData]) => [
            formatDate(date, 'mmm yyyy'),
            usageData,
          ]),
        },
      ];
    },
  },
  apollo: {
    projectsUsageData: {
      // TODO refactor this component to fetch a years worth of data at a time and display arbitrary months of data
      // instead of using explicit "previous" and "current" months: https://gitlab.com/gitlab-org/gitlab/-/issues/429312
      query: getGroupCurrentAndPrevProductAnalyticsUsageQuery,
      variables() {
        return {
          namespacePath: this.namespacePath,
          currentYear: this.currentMonth.getFullYear(),
          previousYear: this.previousMonth.getFullYear(),

          // JS `getMonth()` is 0 based
          currentMonth: this.currentMonth.getMonth() + 1,
          previousMonth: this.previousMonth.getMonth() + 1,
        };
      },
      update(data) {
        return [
          [this.previousMonth, this.sumProjectEvents(data.previous.projects.nodes)],
          [this.currentMonth, this.sumProjectEvents(data.current.projects.nodes)],
        ];
      },
      error(error) {
        this.error = error;
        Sentry.captureException(error);
      },
    },
  },
  methods: {
    sumProjectEvents(projects) {
      return projects.reduce(
        (sum, project) => sum + (project.productAnalyticsEventsStored || 0),
        0,
      );
    },
  },
  CHART_OPTIONS: {
    yAxis: {
      name: s__('Analytics|Events'),
    },
    xAxis: {
      name: s__('Analytics|Month'),
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
    <h2 class="gl-font-lg">{{ s__('Analytics|Usage by month') }}</h2>
    <p>
      <gl-sprintf
        :message="
          s__(
            'Analytics|Product analytics usage is calculated based on the total number of events received from projects within the group. %{linkStart}Learn more%{linkEnd}.',
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
          'Analytics|Something went wrong while loading product analytics usage data. Refresh the page to try again.',
        )
      }}
    </gl-alert>
    <gl-skeleton-loader v-else-if="isLoading" :lines="3" />
    <template v-else>
      <gl-area-chart :data="chartData" :option="$options.CHART_OPTIONS" />
    </template>
  </section>
</template>

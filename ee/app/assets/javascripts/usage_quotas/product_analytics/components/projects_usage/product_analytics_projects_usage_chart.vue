<script>
import { GlSkeletonLoader, GlTooltipDirective } from '@gitlab/ui';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { s__ } from '~/locale';
import { projectsUsageDataValidator } from '../utils';

export default {
  name: 'ProductAnalyticsProjectsUsageChart',
  components: {
    GlColumnChart,
    GlSkeletonLoader,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    projectsUsageData: {
      type: Array,
      required: false,
      default: null,
      validator: projectsUsageDataValidator,
    },
  },
  computed: {
    showChart() {
      return this.projectsUsageData && this.projectsUsageData?.length !== 0;
    },
    chartSeries() {
      return [
        {
          name: s__('Analytics|Previous month'),
          stack: 'previous',
          data: this.projectsUsageData?.map((project) => {
            return [project.name, project.previousEvents];
          }),
        },
        {
          name: s__('Analytics|Current month to date'),
          stack: 'current',
          data: this.projectsUsageData?.map((project) => {
            return [project.name, project.currentEvents];
          }),
        },
      ];
    },
  },
};
</script>
<template>
  <div class="gl-mb-7">
    <gl-skeleton-loader v-if="isLoading" :lines="3" />
    <gl-column-chart
      v-else-if="showChart"
      :bars="chartSeries"
      x-axis-type="category"
      :x-axis-title="s__('Analytics|Projects')"
      :y-axis-title="s__('Analytics|Events')"
    />
  </div>
</template>

<script>
import ProductAnalyticsGroupUsageChart from './product_analytics_group_usage_chart.vue';
import ProductAnalyticsProjectsUsage from './projects_usage/product_analytics_projects_usage.vue';

export default {
  name: 'ProductAnalyticsUsageQuotaApp',
  components: {
    ProductAnalyticsGroupUsageChart,
    ProductAnalyticsProjectsUsage,
  },
};
</script>
<template>
  <section>
    <product-analytics-group-usage-chart />
    <product-analytics-projects-usage />
  </section>
</template>

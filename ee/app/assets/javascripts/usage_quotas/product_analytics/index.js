import Vue from 'vue';
import ProductAnalyticsUsageQuotaApp from 'ee/usage_quotas/product_analytics/components/product_analytics_usage_quota_app.vue';

export default (containerId = 'js-product-analytics-usage-quota-app') => {
  const el = document.getElementById(containerId);

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    name: 'ProductAnalyticsUsageQuotaRoot',
    render(createElement) {
      return createElement(ProductAnalyticsUsageQuotaApp);
    },
  });
};

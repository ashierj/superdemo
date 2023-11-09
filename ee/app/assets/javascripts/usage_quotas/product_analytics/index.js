import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { parseBoolean } from '~/lib/utils/common_utils';
import apolloProvider from 'ee/usage_quotas/shared/provider';

import ProductAnalyticsUsageQuotaApp from './components/product_analytics_usage_quota_app.vue';

Vue.use(VueApollo);

export default (containerId = 'js-product-analytics-usage-quota-app') => {
  const el = document.getElementById(containerId);

  if (!el) {
    return false;
  }

  const { namespacePath, emptyStateIllustrationPath, productAnalyticsEnabled } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    name: 'ProductAnalyticsUsageQuotaRoot',
    provide: {
      namespacePath,
      emptyStateIllustrationPath,
      productAnalyticsEnabled: parseBoolean(productAnalyticsEnabled),
    },
    render(createElement) {
      return createElement(ProductAnalyticsUsageQuotaApp);
    },
  });
};

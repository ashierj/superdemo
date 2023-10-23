import { shallowMount } from '@vue/test-utils';
import ProductAnalyticsUsageQuotaApp from 'ee/usage_quotas/product_analytics/components/product_analytics_usage_quota_app.vue';

describe('Product analytics usage quota app', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(ProductAnalyticsUsageQuotaApp, {});
  };

  it('renders an empty placeholder app', () => {
    createComponent();

    expect(wrapper.find('section').exists()).toBe(true);
  });
});

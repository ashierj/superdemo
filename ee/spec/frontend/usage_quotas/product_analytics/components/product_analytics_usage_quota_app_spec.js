import { shallowMount } from '@vue/test-utils';
import ProductAnalyticsUsageQuotaApp from 'ee/usage_quotas/product_analytics/components/product_analytics_usage_quota_app.vue';
import ProductAnalyticsProjectsUsage from 'ee/usage_quotas/product_analytics/components/projects_usage/product_analytics_projects_usage.vue';

describe('ProductAnalyticsUsageQuotaApp', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findProductAnalyticsGroupUsageChart = () =>
    wrapper.findComponent(ProductAnalyticsProjectsUsage);
  const findProductAnalyticsProjectsUsage = () =>
    wrapper.findComponent(ProductAnalyticsProjectsUsage);

  const createComponent = () => {
    wrapper = shallowMount(ProductAnalyticsUsageQuotaApp, {});
  };

  it('renders the monthly group usage chart', () => {
    createComponent();

    expect(findProductAnalyticsGroupUsageChart().exists()).toBe(true);
  });

  it('renders the projects usage breakdown', () => {
    createComponent();

    expect(findProductAnalyticsProjectsUsage().exists()).toBe(true);
  });
});

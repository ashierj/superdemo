import MetricsDetails from 'ee/metrics/details/metrics_details.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DetailsIndex from 'ee/metrics/details_index.vue';
import ObservabilityContainer from '~/observability/components/observability_container.vue';

describe('DetailsIndex', () => {
  const props = {
    metricId: 'test.metric',
    metricsIndexUrl: 'https://example.com/metrics/index',
    apiConfig: {
      oauthUrl: 'https://example.com/oauth',
      tracingUrl: 'https://example.com/tracing',
      provisioningUrl: 'https://example.com/provisioning',
      servicesUrl: 'https://example.com/services',
      operationsUrl: 'https://example.com/operations',
      metricsUrl: 'https://example.com/metricsUrl',
      metricsSearchUrl: 'https://example.com/metricsSearchUrl',
    },
  };

  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMountExtended(DetailsIndex, {
      propsData: props,
    });
  };

  it('renders ObservabilityContainer component', () => {
    mountComponent();

    const observabilityContainer = wrapper.findComponent(ObservabilityContainer);
    expect(observabilityContainer.exists()).toBe(true);
    expect(observabilityContainer.props('apiConfig')).toStrictEqual(props.apiConfig);
  });

  it('renders MetricsDetails component inside ObservabilityContainer', () => {
    mountComponent();

    const observabilityContainer = wrapper.findComponent(ObservabilityContainer);
    const detailsCmp = observabilityContainer.findComponent(MetricsDetails);
    expect(detailsCmp.exists()).toBe(true);
    expect(detailsCmp.props('metricId')).toBe(props.metricId);
    expect(detailsCmp.props('metricsIndexUrl')).toBe(props.metricsIndexUrl);
  });
});

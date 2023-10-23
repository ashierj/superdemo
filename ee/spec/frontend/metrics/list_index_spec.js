import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ListIndex from 'ee/metrics/list_index.vue';
import ObservabilityContainer from '~/observability/components/observability_container.vue';

describe('ListIndex', () => {
  const props = {
    oauthUrl: 'https://example.com/oauth',
    tracingUrl: 'https://example.com/tracing',
    provisioningUrl: 'https://example.com/provisioning',
    servicesUrl: 'https://example.com/services',
    operationsUrl: 'https://example.com/operations',
  };

  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMountExtended(ListIndex, {
      propsData: props,
    });
  };

  it('renders ObservabilityContainer component', () => {
    mountComponent();

    expect(wrapper.findComponent(ObservabilityContainer).props()).toMatchObject(props);
  });
});

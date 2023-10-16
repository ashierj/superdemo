import { GlFilteredSearch } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ServiceToken from 'ee/tracing/components/service_search_token.vue';
import TracingListFilteredSearch from 'ee/tracing/components/tracing_list_filtered_search.vue';

describe('TracingListFilteredSearch', () => {
  let wrapper;
  let observabilityClientMock;

  const initialFilters = [
    { type: 'period', value: '1h' },
    { type: 'service_name', value: 'example-service' },
  ];

  beforeEach(() => {
    observabilityClientMock = {
      fetchServices: jest.fn(),
    };

    wrapper = shallowMountExtended(TracingListFilteredSearch, {
      propsData: {
        initialFilters,
        observabilityClient: observabilityClientMock,
      },
    });
  });

  it('renders the component', () => {
    expect(wrapper.exists()).toBe(true);
  });

  it('sets initialFilters prop correctly', () => {
    expect(wrapper.findComponent(GlFilteredSearch).props('value')).toEqual(initialFilters);
  });

  it('emits submit event on filtered search submit', () => {
    wrapper
      .findComponent(GlFilteredSearch)
      .vm.$emit('submit', { filters: [{ type: 'period', value: '1h' }] });

    expect(wrapper.emitted('submit')).toHaveLength(1);
    expect(wrapper.emitted('submit')[0][0]).toEqual({
      filters: [{ type: 'period', value: '1h' }],
    });
  });

  describe('service token', () => {
    it('configure the service token', () => {
      const tokens = wrapper.findComponent(GlFilteredSearch).props('availableTokens');
      const serviceToken = tokens.find((t) => t.type === 'service-name');
      expect(serviceToken.token).toBe(ServiceToken);
      expect(serviceToken.fetchServices).toBe(observabilityClientMock.fetchServices);
    });
  });
});

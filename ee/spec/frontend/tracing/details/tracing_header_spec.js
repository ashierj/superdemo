import TracingHeader from 'ee/tracing/details/tracing_header.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('TracingHeader', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMountExtended(TracingHeader, {
      propsData: {
        trace: {
          service_name: 'Service',
          operation: 'Operation',
          timestamp: 1692021937219,
          duration_nano: 1000000,
          total_spans: 10,
        },
      },
    });
  });

  it('renders the correct title', () => {
    expect(wrapper.find('h1').text()).toBe('Service : Operation');
  });

  it('renders the correct trace date', () => {
    expect(wrapper.findByTestId('trace-date-card').text()).toMatchInterpolatedText(
      'Trace start Aug 14, 2023 14:05:37.219 UTC',
    );
  });

  it('renders the correct trace duration', () => {
    expect(wrapper.findByTestId('trace-duration-card').text()).toMatchInterpolatedText(
      'Duration 1.00 ms',
    );
  });

  it('renders the correct total spans', () => {
    expect(wrapper.findByTestId('trace-spans-card').text()).toMatchInterpolatedText(
      'Total spans 10',
    );
  });
});

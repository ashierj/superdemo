import { GlLoadingIcon } from '@gitlab/ui';
import MetricsDetails from 'ee/metrics/details/metrics_details.vue';
import { createMockClient } from 'helpers/mock_observability_client';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { visitUrl, isSafeURL } from '~/lib/utils/url_utility';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

describe('MetricsDetails', () => {
  let wrapper;
  let observabilityClientMock;

  const METRIC_ID = 'test.metric';
  const METRICS_INDEX_URL = 'https://www.gitlab.com/flightjs/Flight/-/metrics';

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findMetricDetails = () => wrapper.findComponentByTestId('metric-details');

  const props = {
    metricId: METRIC_ID,
    metricsIndexUrl: METRICS_INDEX_URL,
  };

  const mountComponent = async () => {
    wrapper = shallowMountExtended(MetricsDetails, {
      propsData: {
        ...props,
        observabilityClient: observabilityClientMock,
      },
    });
    await waitForPromises();
  };

  beforeEach(() => {
    isSafeURL.mockReturnValue(true);

    observabilityClientMock = createMockClient();
  });

  it('renders the loading indicator while checking if observability is enabled', () => {
    mountComponent();

    expect(findLoadingIcon().exists()).toBe(true);
    expect(observabilityClientMock.isObservabilityEnabled).toHaveBeenCalled();
  });

  describe('when observability is enabled', () => {
    beforeEach(async () => {
      observabilityClientMock.isObservabilityEnabled.mockResolvedValueOnce(true);
      await mountComponent();
    });

    it('renders the metrics details', () => {
      expect(observabilityClientMock.isObservabilityEnabled).toHaveBeenCalled();
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findMetricDetails().exists()).toBe(true);
    });
  });

  describe('when observability is not enabled', () => {
    beforeEach(async () => {
      observabilityClientMock.isObservabilityEnabled.mockResolvedValueOnce(false);
      await mountComponent();
    });

    it('redirects to metricsIndexUrl', () => {
      expect(visitUrl).toHaveBeenCalledWith(props.metricsIndexUrl);
    });

    it('does not render the metrics details', () => {
      expect(findMetricDetails().exists()).toBe(false);
    });
  });

  describe('error handling', () => {
    it('if isObservabilityEnabled fails, it renders an alert and empty page', async () => {
      observabilityClientMock.isObservabilityEnabled.mockRejectedValueOnce('error');

      await mountComponent();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Error: Failed to load metrics details. Try reloading the page.',
      });
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findMetricDetails().exists()).toBe(false);
    });
  });
});

import { GlLoadingIcon } from '@gitlab/ui';
import MetricsDetails from 'ee/metrics/details/metrics_details.vue';
import { createMockClient } from 'helpers/mock_observability_client';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { visitUrl, isSafeURL } from '~/lib/utils/url_utility';
import MetricsChart from 'ee/metrics/details/metrics_chart.vue';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

describe('MetricsDetails', () => {
  let wrapper;
  let observabilityClientMock;

  const METRIC_ID = 'test.metric';
  const METRIC_TYPE = 'Sum';
  const METRICS_INDEX_URL = 'https://www.gitlab.com/flightjs/Flight/-/metrics';

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findMetricDetails = () => wrapper.findComponentByTestId('metric-details');
  const findHeader = () => wrapper.findComponentByTestId('metric-header');

  const props = {
    metricId: METRIC_ID,
    metricType: METRIC_TYPE,
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
    const mockMetricData = [
      {
        name: 'container_cpu_usage_seconds_total',
        description: 'System disk operations',
        type: 'Gauge',
        unit: 'gb',
        attributes: {
          beta_kubernetes_io_arch: 'amd64',
          beta_kubernetes_io_instance_type: 'n1-standard-4',
          beta_kubernetes_io_os: 'linux',
          env: 'production',
        },
        values: [
          [1700118610000, 0.25595267476015443],
          [1700118660000, 0.1881374588830907],
          [1700118720000, 0.28915416028993485],
        ],
      },
    ];
    beforeEach(async () => {
      observabilityClientMock.isObservabilityEnabled.mockResolvedValueOnce(true);
      observabilityClientMock.fetchMetric.mockResolvedValueOnce(mockMetricData);
      await mountComponent();
    });

    it('fetches details and renders the metrics details', () => {
      expect(observabilityClientMock.isObservabilityEnabled).toHaveBeenCalled();
      expect(observabilityClientMock.fetchMetric).toHaveBeenCalledWith(METRIC_ID, METRIC_TYPE);
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findMetricDetails().exists()).toBe(true);
    });

    it('renders the details chart', () => {
      const chart = findMetricDetails().findComponent(MetricsChart);
      expect(chart.exists()).toBe(true);
      expect(chart.props('metricData')).toEqual(mockMetricData);
    });

    describe('header', () => {
      it('renders the details header', () => {
        const header = findHeader();
        expect(header.exists()).toBe(true);
        expect(header.find(`[data-testid="metric-title"]`).text()).toBe(
          'container_cpu_usage_seconds_total',
        );
        expect(header.find(`[data-testid="metric-description"]`).text()).toBe(
          'System disk operations',
        );
        expect(header.find(`[data-testid="metric-type"]`).text()).toBe('Type:\u00a0Gauge');
      });

      it('does not render the header if the metric data is empty', () => {
        observabilityClientMock.fetchMetric.mockResolvedValueOnce([]);

        mountComponent();

        expect(findHeader().exists()).toBe(false);
      });
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

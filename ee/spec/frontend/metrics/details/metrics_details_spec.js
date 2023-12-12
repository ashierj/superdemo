import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
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

  const findHeader = () => findMetricDetails().find(`[data-testid="metric-header"]`);
  const findHeaderTitle = () => findHeader().find(`[data-testid="metric-title"]`);
  const findHeaderType = () => findHeader().find(`[data-testid="metric-type"]`);
  const findHeaderDescription = () => findHeader().find(`[data-testid="metric-description"]`);

  const findChart = () => findMetricDetails().findComponent(MetricsChart);
  const findEmptyState = () => findMetricDetails().findComponent(GlEmptyState);

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
    expect(findMetricDetails().exists()).toBe(false);
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

    it('renders the details header', () => {
      expect(findHeader().exists()).toBe(true);
      expect(findHeaderTitle().text()).toBe(METRIC_ID);
      expect(findHeaderType().text()).toBe(`Type:\u00a0${METRIC_TYPE}`);
      expect(findHeaderDescription().text()).toBe('System disk operations');
    });

    describe('with no data', () => {
      beforeEach(async () => {
        observabilityClientMock.fetchMetric.mockResolvedValueOnce([]);

        await mountComponent();
      });
      it('only renders the title and type headers', () => {
        expect(findHeaderTitle().text()).toBe(METRIC_ID);
        expect(findHeaderType().text()).toBe(`Type:\u00a0${METRIC_TYPE}`);
        expect(findHeaderDescription().text()).toBe('');
      });
      it('renders the empty state', () => {
        expect(findEmptyState().exists()).toBe(true);
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
  });

  describe('error handling', () => {
    beforeEach(async () => {
      observabilityClientMock.isObservabilityEnabled.mockRejectedValueOnce('error');

      await mountComponent();
    });

    describe.each([
      ['isObservabilityEnabled', () => observabilityClientMock.isObservabilityEnabled],
      ['fetchMetric', () => observabilityClientMock.fetchMetric],
    ])('when %s fails', (_, mockFn) => {
      beforeEach(async () => {
        mockFn().mockRejectedValueOnce('error');
        await mountComponent();
      });
      it('renders an alert', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Error: Failed to load metrics details. Try reloading the page.',
        });
      });

      it('only renders the empty state and header', () => {
        expect(findMetricDetails().exists()).toBe(true);
        expect(findEmptyState().exists()).toBe(true);
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findHeader().exists()).toBe(true);
        expect(findChart().exists()).toBe(false);
      });
    });
  });
});

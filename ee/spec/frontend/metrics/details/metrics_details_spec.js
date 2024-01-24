import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import MetricsDetails from 'ee/metrics/details/metrics_details.vue';
import { createMockClient } from 'helpers/mock_observability_client';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { visitUrl, isSafeURL } from '~/lib/utils/url_utility';
import MetricsChart from 'ee/metrics/details/metrics_chart.vue';
import FilteredSearch from 'ee/metrics/details/filter_bar/metrics_filtered_search.vue';
import { ingestedAtTimeAgo } from 'ee/metrics/utils';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');
jest.mock('ee/metrics/utils');

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
  const findHeaderLastIngested = () => findHeader().find(`[data-testid="metric-last-ingested"]`);

  const findChart = () => findMetricDetails().findComponent(MetricsChart);
  const findEmptyState = () => findMetricDetails().findComponent(GlEmptyState);

  const defaultProps = {
    metricId: METRIC_ID,
    metricType: METRIC_TYPE,
    metricsIndexUrl: METRICS_INDEX_URL,
  };

  const mountComponent = async (props = {}) => {
    wrapper = shallowMountExtended(MetricsDetails, {
      propsData: {
        ...defaultProps,
        ...props,
        observabilityClient: observabilityClientMock,
      },
    });
    await waitForPromises();
  };

  beforeEach(() => {
    isSafeURL.mockReturnValue(true);

    ingestedAtTimeAgo.mockReturnValue('3 days ago');

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

    const mockSearchMetadata = {
      name: 'cpu_seconds_total',
      type: 'sum',
      description: 'System disk operations',
      last_ingested_at: 1705374438711900000,
      attribute_keys: ['host.name', 'host.dc', 'host.type'],
      supported_aggregations: ['1m', '1h'],
      supported_functions: ['min', 'max', 'avg', 'sum', 'count'],
      default_group_by_attributes: ['host.name'],
      default_group_by_function: ['avg'],
    };

    beforeEach(async () => {
      observabilityClientMock.isObservabilityEnabled.mockResolvedValue(true);
      observabilityClientMock.fetchMetric.mockResolvedValue(mockMetricData);
      observabilityClientMock.fetchMetricSearchMetadata.mockResolvedValue(mockSearchMetadata);

      await mountComponent();
    });

    it('fetches data', () => {
      expect(observabilityClientMock.isObservabilityEnabled).toHaveBeenCalled();
      expect(observabilityClientMock.fetchMetric).toHaveBeenCalledWith(METRIC_ID, METRIC_TYPE);
      expect(observabilityClientMock.fetchMetricSearchMetadata).toHaveBeenCalledWith(
        METRIC_ID,
        METRIC_TYPE,
      );
    });

    it('renders the metrics details', () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findMetricDetails().exists()).toBe(true);
    });

    it('renders the FilteredSearch component', () => {
      const filteredSearch = findMetricDetails().findComponent(FilteredSearch);
      expect(filteredSearch.exists()).toBe(true);
      // TODO get searchConfig from API https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2488
      expect(Object.keys(filteredSearch.props('searchConfig'))).toEqual(
        expect.arrayContaining([
          'dimensions',
          'groupByFunctions',
          'defaultGroupByFunction',
          'defaultGroupByDimensions',
        ]),
      );
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
      expect(findHeaderLastIngested().text()).toBe('Last ingested:\u00a03 days ago');
      expect(ingestedAtTimeAgo).toHaveBeenCalledWith(mockSearchMetadata.last_ingested_at);
    });

    describe('with no data', () => {
      beforeEach(async () => {
        observabilityClientMock.fetchMetric.mockResolvedValue([]);

        await mountComponent();
      });

      it('renders the header', () => {
        expect(findHeaderTitle().text()).toBe(METRIC_ID);
        expect(findHeaderType().text()).toBe(`Type:\u00a0${METRIC_TYPE}`);
        expect(findHeaderLastIngested().text()).toBe('Last ingested:\u00a03 days ago');
        expect(findHeaderDescription().text()).toBe('System disk operations');
      });
      it('renders the empty state', () => {
        expect(findEmptyState().exists()).toBe(true);
        expect(findEmptyState().text()).toContain('Last ingested:\u00a03 days ago');
      });
    });
  });

  describe('when observability is not enabled', () => {
    beforeEach(async () => {
      observabilityClientMock.isObservabilityEnabled.mockResolvedValue(false);
      await mountComponent();
    });

    it('redirects to metricsIndexUrl', () => {
      expect(visitUrl).toHaveBeenCalledWith(defaultProps.metricsIndexUrl);
    });

    it('does not fetch data', () => {
      expect(observabilityClientMock.isObservabilityEnabled).toHaveBeenCalled();
      expect(observabilityClientMock.fetchMetric).not.toHaveBeenCalled();
      expect(observabilityClientMock.fetchMetricSearchMetadata).not.toHaveBeenCalled();
    });
  });

  describe('error handling', () => {
    beforeEach(async () => {
      observabilityClientMock.isObservabilityEnabled.mockRejectedValueOnce('error');

      await mountComponent();
    });

    describe.each([
      ['isObservabilityEnabled', () => observabilityClientMock.isObservabilityEnabled],
      ['fetchMetricSearchMetadata', () => observabilityClientMock.fetchMetricSearchMetadata],
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

    it('does not fetch metric data if fetching search metadata fails', async () => {
      observabilityClientMock.fetchMetricSearchMetadata.mockRejectedValueOnce('error');
      await mountComponent();
      expect(observabilityClientMock.fetchMetric).not.toHaveBeenCalled();
    });

    it('renders an alert if metricId is missing', async () => {
      await mountComponent({ metricId: undefined });

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Error: Failed to load metrics details. Try reloading the page.',
      });
    });

    it('renders an alert if metricType is missing', async () => {
      await mountComponent({ metricType: undefined });

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Error: Failed to load metrics details. Try reloading the page.',
      });
    });
  });
});

import { GlLoadingIcon } from '@gitlab/ui';
import MetricsTable from 'ee/metrics/list/metrics_table.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MetricsList from 'ee/metrics/list/metrics_list.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import * as urlUtility from '~/lib/utils/url_utility';
import setWindowLocation from 'helpers/set_window_location_helper';
import { mockMetrics } from './mock_data';

jest.mock('~/alert');

describe('MetricsComponent', () => {
  let wrapper;
  let observabilityClientMock;

  const mockResponse = {
    metrics: [...mockMetrics],
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findMetricsTable = () => wrapper.findComponent(MetricsTable);

  const mountComponent = async () => {
    wrapper = shallowMountExtended(MetricsList, {
      propsData: {
        observabilityClient: observabilityClientMock,
      },
    });
    await waitForPromises();
  };

  beforeEach(() => {
    observabilityClientMock = {
      fetchMetrics: jest.fn().mockResolvedValue(mockResponse),
    };
  });

  it('renders the loading indicator while fetching metrics', () => {
    mountComponent();

    expect(findLoadingIcon().exists()).toBe(true);
    expect(findMetricsTable().exists()).toBe(false);
    expect(observabilityClientMock.fetchMetrics).toHaveBeenCalled();
  });

  it('renders the MetricsTable when fetching metrics is done', async () => {
    await mountComponent();

    expect(findLoadingIcon().exists()).toBe(false);
    expect(findMetricsTable().exists()).toBe(true);
    expect(findMetricsTable().props('metrics')).toEqual(mockResponse.metrics);
  });

  it('if fetchMetrics fails, it renders an alert and empty list', async () => {
    observabilityClientMock.fetchMetrics.mockRejectedValue('error');

    await mountComponent();

    expect(createAlert).toHaveBeenLastCalledWith({ message: 'Failed to load metrics.' });
    expect(findMetricsTable().exists()).toBe(true);
    expect(findMetricsTable().props('metrics')).toEqual([]);
  });

  describe('on metric-clicked', () => {
    let visitUrlMock;
    const BASE_PATH = '/projectX/-/metrics';

    beforeEach(async () => {
      setWindowLocation(BASE_PATH);
      visitUrlMock = jest.spyOn(urlUtility, 'visitUrl').mockReturnValue({});

      await mountComponent();
    });

    it('redirects to the details url', () => {
      findMetricsTable().vm.$emit('metric-clicked', { metricId: 'test.metric' });

      expect(visitUrlMock).toHaveBeenCalledTimes(1);
      expect(visitUrlMock).toHaveBeenCalledWith(`${BASE_PATH}/test.metric`, false);
    });

    it('opens a new tab if clicked with meta key', () => {
      findMetricsTable().vm.$emit('metric-clicked', {
        metricId: 'test.metric',
        clickEvent: { metaKey: true },
      });

      expect(visitUrlMock).toHaveBeenCalledTimes(1);
      expect(visitUrlMock).toHaveBeenCalledWith(`${BASE_PATH}/test.metric`, true);
    });
  });
});

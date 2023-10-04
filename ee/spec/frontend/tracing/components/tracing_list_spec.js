import { GlLoadingIcon, GlInfiniteScroll } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TracingList from 'ee/tracing/components/tracing_list.vue';
import TracingEmptyState from 'ee/tracing/components/tracing_empty_state.vue';
import TracingTableList from 'ee/tracing/components/tracing_table_list.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import * as urlUtility from '~/lib/utils/url_utility';
import {
  queryToFilterObj,
  filterObjToQuery,
  filterObjToFilterToken,
  filterTokensToFilterObj,
} from 'ee/tracing/filters';
import FilteredSearch from 'ee/tracing/components/tracing_list_filtered_search.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import setWindowLocation from 'helpers/set_window_location_helper';

jest.mock('~/alert');
jest.mock('ee/tracing/filters');

describe('TracingList', () => {
  let wrapper;
  let observabilityClientMock;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(TracingEmptyState);
  const findTableList = () => wrapper.findComponent(TracingTableList);
  const findFilteredSearch = () => wrapper.findComponent(FilteredSearch);
  const findUrlSync = () => wrapper.findComponent(UrlSync);
  const findInfiniteScrolling = () => wrapper.findComponent(GlInfiniteScroll);

  const mockResponse = {
    traces: [{ trace_id: 'trace1' }, { trace_id: 'trace2' }],
    next_page_token: 'page-2',
  };

  const mountComponent = async () => {
    wrapper = shallowMountExtended(TracingList, {
      propsData: {
        observabilityClient: observabilityClientMock,
      },
    });
    await waitForPromises();
  };

  beforeEach(() => {
    observabilityClientMock = {
      isTracingEnabled: jest.fn().mockResolvedValue(true),
      enableTraces: jest.fn().mockResolvedValue(true),
      fetchTraces: jest.fn().mockResolvedValue(mockResponse),
    };
    queryToFilterObj.mockReturnValue({});
    filterObjToQuery.mockReturnValue({});
    filterTokensToFilterObj.mockReturnValue({});
  });

  it('renders the loading indicator while checking if tracing is enabled', () => {
    mountComponent();
    expect(findLoadingIcon().exists()).toBe(true);
    expect(findEmptyState().exists()).toBe(false);
    expect(findTableList().exists()).toBe(false);
    expect(findFilteredSearch().exists()).toBe(false);
    expect(findUrlSync().exists()).toBe(false);
    expect(findInfiniteScrolling().exists()).toBe(false);
    expect(observabilityClientMock.isTracingEnabled).toHaveBeenCalled();
  });

  describe('when tracing is enabled', () => {
    beforeEach(async () => {
      await mountComponent();
    });

    it('fetches the traces and renders the trace list with filtered search', () => {
      expect(observabilityClientMock.isTracingEnabled).toHaveBeenCalled();
      expect(observabilityClientMock.fetchTraces).toHaveBeenCalled();
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(false);
      expect(findTableList().exists()).toBe(true);
      expect(findFilteredSearch().exists()).toBe(true);
      expect(findUrlSync().exists()).toBe(true);
      expect(findTableList().props('traces')).toEqual(mockResponse.traces);
    });

    it('calls fetchTraces method when TracingTableList emits reload event', () => {
      observabilityClientMock.fetchTraces.mockClear();

      findTableList().vm.$emit('reload');

      expect(observabilityClientMock.fetchTraces).toHaveBeenCalledTimes(1);
    });

    it('on trace selection it redirects to the details url', () => {
      setWindowLocation('base_path');
      const visitUrlMock = jest.spyOn(urlUtility, 'visitUrl').mockReturnValue({});

      findTableList().vm.$emit('trace-selected', { traceId: 'test-trace-id' });

      expect(visitUrlMock).toHaveBeenCalledTimes(1);
      expect(visitUrlMock).toHaveBeenCalledWith('/base_path/test-trace-id');
    });
  });

  describe('filtered search', () => {
    let mockFilterObj;
    let mockFilterToken;
    let mockQuery;
    let mockUpdatedFilterObj;

    beforeEach(async () => {
      setWindowLocation('?trace-id=foo');

      mockFilterObj = { mock: 'filter-obj' };
      queryToFilterObj.mockReturnValue(mockFilterObj);

      mockFilterToken = ['mock-token'];
      filterObjToFilterToken.mockReturnValue(mockFilterToken);

      mockQuery = { mock: 'query' };
      filterObjToQuery.mockReturnValueOnce(mockQuery);

      mockUpdatedFilterObj = { mock: 'filter-obj-upd' };
      filterTokensToFilterObj.mockReturnValue(mockUpdatedFilterObj);

      await mountComponent();
    });

    it('renders FilteredSeach with initial filters parsed from window.location', () => {
      expect(queryToFilterObj).toHaveBeenCalledWith('?trace-id=foo');
      expect(filterObjToFilterToken).toHaveBeenLastCalledWith(mockFilterObj);
      expect(findFilteredSearch().props('initialFilters')).toBe(mockFilterToken);
    });

    it('renders UrlSync and sets query prop', () => {
      expect(filterObjToQuery).toHaveBeenLastCalledWith(mockFilterObj);
      expect(findUrlSync().props('query')).toBe(mockQuery);
    });

    it('process filters on search submit', async () => {
      const mockUpdatedQuery = { mock: 'updated-query' };
      filterObjToQuery.mockReturnValueOnce(mockUpdatedQuery);
      const mockFilters = { mock: 'some-filter' };

      findFilteredSearch().vm.$emit('submit', mockFilters);
      await waitForPromises();

      expect(filterTokensToFilterObj).toHaveBeenLastCalledWith(mockFilters);
      expect(filterObjToQuery).toHaveBeenLastCalledWith(mockUpdatedFilterObj);
      expect(findUrlSync().props('query')).toBe(mockUpdatedQuery);
    });

    it('fetches traces with filters', () => {
      expect(observabilityClientMock.fetchTraces).toHaveBeenLastCalledWith({
        filters: mockFilterObj,
        pageSize: 50,
        pageToken: null,
      });

      findFilteredSearch().vm.$emit('submit', {});

      expect(observabilityClientMock.fetchTraces).toHaveBeenLastCalledWith({
        filters: mockUpdatedFilterObj,
        pageSize: 50,
        pageToken: null,
      });
    });
  });

  describe('infinite scrolling', () => {
    const bottomReached = async () => {
      findInfiniteScrolling().vm.$emit('bottomReached');
      await waitForPromises();
    };

    const findLegend = () =>
      findInfiniteScrolling().find('[data-testid="tracing-infinite-scrolling-legend"]');

    beforeEach(async () => {
      await mountComponent();
    });

    it('renders the list with infinite scrolling', () => {
      const infiniteScrolling = findInfiniteScrolling();
      expect(infiniteScrolling.exists()).toBe(true);
      expect(infiniteScrolling.props('fetchedItems')).toBe(mockResponse.traces.length);
      expect(infiniteScrolling.getComponent(TracingTableList).exists()).toBe(true);
    });

    it('fetches the next page of traces when bottom reached', async () => {
      const nextPageResponse = {
        traces: [{ trace_id: 'trace-3' }],
        next_page_token: 'page-3',
      };
      observabilityClientMock.fetchTraces.mockReturnValueOnce(nextPageResponse);

      await bottomReached();

      expect(observabilityClientMock.fetchTraces).toHaveBeenLastCalledWith({
        filters: {},
        pageSize: 50,
        pageToken: 'page-2',
      });

      expect(findInfiniteScrolling().props('fetchedItems')).toBe(
        mockResponse.traces.length + nextPageResponse.traces.length,
      );
      expect(findTableList().props('traces')).toEqual([
        ...mockResponse.traces,
        ...nextPageResponse.traces,
      ]);
    });

    it('does not update the next_page_token if missing - i.e. it reached the last page', async () => {
      observabilityClientMock.fetchTraces.mockReturnValueOnce({
        traces: [],
      });

      await bottomReached();

      expect(observabilityClientMock.fetchTraces).toHaveBeenLastCalledWith({
        filters: {},
        pageSize: 50,
        pageToken: 'page-2',
      });
    });

    it('does not show legend when there are 0 items', async () => {
      observabilityClientMock.fetchTraces.mockReturnValue({
        traces: [],
      });
      await mountComponent();
      expect(findLegend().text()).toBe('');
    });

    it('shows the number of fetched items as the legend', () => {
      expect(findLegend().text()).toBe(`Showing ${mockResponse.traces.length} traces`);
    });

    it('shows the spinner when fetching the next page', async () => {
      bottomReached();
      await nextTick();

      expect(findInfiniteScrolling().findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(findLegend().exists()).toBe(false);
    });

    it('when filters are changed, pagination and traces are reset', async () => {
      observabilityClientMock.fetchTraces.mockReturnValueOnce({
        traces: [{ trace_id: 'trace-3' }],
        next_page_token: 'page-3',
      });
      await bottomReached();

      findFilteredSearch().vm.$emit('submit', {});
      await waitForPromises();

      expect(observabilityClientMock.fetchTraces).toHaveBeenLastCalledWith({
        filters: {},
        pageSize: 50,
        pageToken: null,
      });

      expect(findTableList().props('traces')).toEqual(mockResponse.traces);
    });
  });

  describe('when tracing is not enabled', () => {
    beforeEach(async () => {
      observabilityClientMock.isTracingEnabled.mockResolvedValue(false);

      await mountComponent();
    });

    it('renders TracingEmptyState', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('calls enableTracing when TracingEmptyState emits enable-tracing', () => {
      findEmptyState().vm.$emit('enable-tracing');

      expect(observabilityClientMock.enableTraces).toHaveBeenCalled();
    });
  });

  describe('error handling', () => {
    it('if isTracingEnabled fails, it renders an alert and empty page', async () => {
      observabilityClientMock.isTracingEnabled.mockRejectedValue('error');

      await mountComponent();

      expect(createAlert).toHaveBeenLastCalledWith({ message: 'Failed to load page.' });
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(false);
      expect(findTableList().exists()).toBe(false);
    });

    it('if fetchTraces fails, it renders an alert and empty list', async () => {
      observabilityClientMock.fetchTraces.mockRejectedValue('error');
      observabilityClientMock.isTracingEnabled.mockReturnValueOnce(true);

      await mountComponent();

      expect(createAlert).toHaveBeenLastCalledWith({ message: 'Failed to load traces.' });
      expect(findTableList().exists()).toBe(true);
      expect(findTableList().props('traces')).toEqual([]);
    });

    it('if enableTraces fails, it renders an alert and empty-state', async () => {
      observabilityClientMock.isTracingEnabled.mockReturnValueOnce(false);
      observabilityClientMock.enableTraces.mockRejectedValue('error');

      await mountComponent();

      findEmptyState().vm.$emit('enable-tracing');
      await waitForPromises();

      expect(createAlert).toHaveBeenLastCalledWith({ message: 'Failed to enable tracing.' });
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(true);
      expect(findTableList().exists()).toBe(false);
    });
  });
});

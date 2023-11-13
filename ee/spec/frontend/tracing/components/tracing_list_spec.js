import { GlLoadingIcon, GlInfiniteScroll } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TracingList from 'ee/tracing/components/tracing_list.vue';
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
import ScatterChart from 'ee/tracing/components/tracing_scatter_chart.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import setWindowLocation from 'helpers/set_window_location_helper';
import * as traceUtils from 'ee/tracing/components/trace_utils';
import { createMockClient } from 'helpers/mock_observability_client';

jest.mock('~/alert');
jest.mock('ee/tracing/filters');

describe('TracingList', () => {
  let wrapper;
  let observabilityClientMock;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTableList = () => wrapper.findComponent(TracingTableList);
  const findFilteredSearch = () => wrapper.findComponent(FilteredSearch);
  const findUrlSync = () => wrapper.findComponent(UrlSync);
  const findInfiniteScrolling = () => wrapper.findComponent(GlInfiniteScroll);
  const findScatterChart = () => wrapper.findComponent(ScatterChart);
  const bottomReached = async () => {
    findInfiniteScrolling().vm.$emit('bottomReached');
    await waitForPromises();
  };

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
    observabilityClientMock = createMockClient();

    observabilityClientMock.fetchTraces.mockResolvedValue(mockResponse);

    queryToFilterObj.mockReturnValue({});
    filterObjToQuery.mockReturnValue({});
    filterTokensToFilterObj.mockReturnValue({});
  });

  describe('fetching traces', () => {
    beforeEach(async () => {
      await mountComponent();
    });

    it('fetches the traces and renders the trace list with filtered search', () => {
      expect(observabilityClientMock.fetchTraces).toHaveBeenCalled();
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findTableList().exists()).toBe(true);
      expect(findFilteredSearch().exists()).toBe(true);
      expect(findUrlSync().exists()).toBe(true);
      expect(findTableList().props('traces')).toEqual(mockResponse.traces);
    });

    describe('on trace-clicked', () => {
      let visitUrlMock;
      beforeEach(() => {
        setWindowLocation('base_path');
        visitUrlMock = jest.spyOn(urlUtility, 'visitUrl').mockReturnValue({});
      });

      it('redirects to the details url', () => {
        findTableList().vm.$emit('trace-clicked', { traceId: 'test-trace-id' });

        expect(visitUrlMock).toHaveBeenCalledTimes(1);
        expect(visitUrlMock).toHaveBeenCalledWith('/base_path/test-trace-id', false);
      });

      it('opens a new tab if clicked with meta key', () => {
        findTableList().vm.$emit('trace-clicked', {
          traceId: 'test-trace-id',
          clickEvent: { metaKey: true },
        });

        expect(visitUrlMock).toHaveBeenCalledTimes(1);
        expect(visitUrlMock).toHaveBeenCalledWith('/base_path/test-trace-id', true);
      });
    });
  });

  describe('filtered search', () => {
    let mockFilterObj;
    let mockFilterToken;
    let mockFilterQuery;
    let mockUpdatedFilterObj;

    beforeEach(async () => {
      setWindowLocation('?trace-id=test-trace-id&sortBy=duration_asc');

      mockFilterObj = { mock: 'filter-obj' };
      queryToFilterObj.mockReturnValue(mockFilterObj);

      mockFilterToken = ['mock-token'];
      filterObjToFilterToken.mockReturnValue(mockFilterToken);

      mockFilterQuery = { mock: 'filter-query' };
      filterObjToQuery.mockReturnValueOnce(mockFilterQuery);

      mockUpdatedFilterObj = { mock: 'filter-query-upd' };
      filterTokensToFilterObj.mockReturnValue(mockUpdatedFilterObj);

      await mountComponent();
    });

    it('sets the client prop', () => {
      expect(findFilteredSearch().props('observabilityClient')).toBe(observabilityClientMock);
    });

    it('renders FilteredSeach with initial filters and sort order parsed from window.location', () => {
      expect(queryToFilterObj).toHaveBeenCalledWith({ 'trace-id': 'test-trace-id' });
      expect(filterObjToFilterToken).toHaveBeenLastCalledWith(mockFilterObj);

      expect(findFilteredSearch().props('initialFilters')).toBe(mockFilterToken);
      expect(findFilteredSearch().props('initialSort')).toBe('duration_asc');
    });

    it('sets FilteredSearch initialSort the default sort order if not specified in the query', async () => {
      setWindowLocation('?trace-id=foo');
      await mountComponent();

      expect(findFilteredSearch().props('initialSort')).toBe('timestamp_desc');
    });

    it('renders UrlSync and sets query prop', () => {
      expect(filterObjToQuery).toHaveBeenLastCalledWith(mockFilterObj);
      expect(findUrlSync().props('query')).toEqual({ ...mockFilterQuery, sortBy: 'duration_asc' });
    });

    it('fetches traces with filters and sort order', () => {
      expect(observabilityClientMock.fetchTraces).toHaveBeenLastCalledWith({
        filters: mockFilterObj,
        pageSize: 500,
        pageToken: null,
        sortBy: 'duration_asc',
      });
    });

    describe('on search submit', () => {
      const mockFilters = { mock: 'some-filter' };
      const mockUpdatedFilterQuery = { mock: 'updated-query' };
      const mockUpdatedFilterToken = ['updated-filter-token'];

      beforeEach(async () => {
        filterObjToQuery.mockReturnValueOnce(mockUpdatedFilterQuery);
        filterObjToFilterToken.mockReturnValue(mockUpdatedFilterToken);

        findFilteredSearch().vm.$emit('submit', mockFilters);
        await waitForPromises();
      });

      it('process filters on search submit', () => {
        expect(filterTokensToFilterObj).toHaveBeenLastCalledWith(mockFilters);
        expect(filterObjToQuery).toHaveBeenLastCalledWith(mockUpdatedFilterObj);
      });

      it('updates the query on search submit', () => {
        expect(findUrlSync().props('query')).toMatchObject(mockUpdatedFilterQuery);
      });

      it('fetches traces with updated filters', () => {
        expect(observabilityClientMock.fetchTraces).toHaveBeenLastCalledWith({
          filters: mockUpdatedFilterObj,
          pageSize: 500,
          pageToken: null,
          sortBy: 'duration_asc',
        });
      });

      it('updates FilteredSearch initialFilters', () => {
        expect(findFilteredSearch().props('initialFilters')).toEqual(mockUpdatedFilterToken);
      });
    });

    describe('on sort order changed', () => {
      beforeEach(async () => {
        findFilteredSearch().vm.$emit('sort', 'timestamp_asc');
        await waitForPromises();
      });

      it('updates the query on search submit', () => {
        expect(findUrlSync().props('query')).toMatchObject({
          sortBy: 'timestamp_asc',
        });
      });

      it('fetches traces with new sort order', () => {
        expect(observabilityClientMock.fetchTraces).toHaveBeenLastCalledWith({
          filters: mockFilterObj,
          pageSize: 500,
          pageToken: null,
          sortBy: 'timestamp_asc',
        });
      });

      it('updates FilteredSearch initial sort', () => {
        expect(findFilteredSearch().props('initialSort')).toEqual('timestamp_asc');
      });
    });
  });

  describe('infinite scrolling', () => {
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
        pageSize: 500,
        pageToken: 'page-2',
        sortBy: 'timestamp_desc',
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
        pageSize: 500,
        pageToken: 'page-2',
        sortBy: 'timestamp_desc',
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
        pageSize: 500,
        pageToken: null,
        sortBy: 'timestamp_desc',
      });

      expect(findTableList().props('traces')).toEqual(mockResponse.traces);
    });

    it('when sort order is changed, pagination and traces are reset', async () => {
      observabilityClientMock.fetchTraces.mockReturnValueOnce({
        traces: [{ trace_id: 'trace-3' }],
        next_page_token: 'page-3',
      });
      await bottomReached();

      findFilteredSearch().vm.$emit('sort', 'duration_desc');
      await waitForPromises();

      expect(observabilityClientMock.fetchTraces).toHaveBeenLastCalledWith({
        filters: {},
        pageSize: 500,
        pageToken: null,
        sortBy: 'duration_desc',
      });

      expect(findTableList().props('traces')).toEqual(mockResponse.traces);
    });
  });

  describe('scatter chart', () => {
    const mockPeriodFilter = (filter) =>
      jest.spyOn(traceUtils, 'periodFilterToDate').mockReturnValue(filter);

    beforeEach(async () => {
      mockPeriodFilter({
        min: new Date('2023-10-09 12:30:00'),
        max: new Date('2023-10-09 15:30:00'),
      });

      await mountComponent();

      wrapper.vm.$refs.tableList.$el.querySelector = jest
        .fn()
        .mockReturnValue({ querySelectorAll: jest.fn().mockReturnValue([]) });

      wrapper.vm.$refs.infiniteScroll.scrollTo = jest.fn();
    });

    it('renders the chart', () => {
      const chart = findScatterChart();
      expect(chart.exists()).toBe(true);
      expect(chart.props('traces')).toEqual(mockResponse.traces);
      expect(chart.props('rangeMin')).toEqual(new Date('2023-10-09 12:30:00'));
      expect(chart.props('rangeMax')).toEqual(new Date('2023-10-09 15:30:00'));
    });

    it('updates the chart boundaries when changing the filters', async () => {
      mockPeriodFilter({
        min: new Date('2023-01-01 00:00:00'),
        max: new Date('2023-01-02 00:00:00'),
      });

      findFilteredSearch().vm.$emit('submit', {});
      await waitForPromises();

      const chart = findScatterChart();
      expect(chart.props('rangeMin')).toEqual(new Date('2023-01-01 00:00:00'));
      expect(chart.props('rangeMax')).toEqual(new Date('2023-01-02 00:00:00'));
    });

    it('does not updates the chart boundaries when scrolling down', async () => {
      mockPeriodFilter({
        min: new Date('2023-01-01 00:00:00'),
        max: new Date('2023-01-02 00:00:00'),
      });

      await bottomReached();

      const chart = findScatterChart();
      expect(chart.props('rangeMin')).toEqual(new Date('2023-10-09 12:30:00'));
      expect(chart.props('rangeMax')).toEqual(new Date('2023-10-09 15:30:00'));
    });

    it('goes to the trace details page on item selection', () => {
      setWindowLocation('base_path');
      const visitUrlMock = jest.spyOn(urlUtility, 'visitUrl').mockReturnValue({});

      findScatterChart().vm.$emit('chart-item-selected', { traceId: 'test-trace-id' });

      expect(visitUrlMock).toHaveBeenCalledTimes(1);
      expect(visitUrlMock).toHaveBeenCalledWith('/base_path/test-trace-id', false);
    });

    it('highlight and scroll to the trace row when over a chart point', async () => {
      wrapper.vm.$refs.tableList.$el.querySelector.mockReturnValueOnce({
        querySelectorAll: jest.fn().mockReturnValue([{ offsetTop: 1234 }]),
      });
      await findScatterChart().vm.$emit('chart-item-over', {
        traceId: mockResponse.traces[0].trace_id,
      });

      expect(findTableList().props('highlightedTraceId')).toBe(mockResponse.traces[0].trace_id);
      expect(wrapper.vm.$refs.infiniteScroll.scrollTo).toHaveBeenCalledWith({
        behavior: 'smooth',
        top: 1234,
      });
    });

    it('stop highlighting the trace row when not over a chart point', async () => {
      await findScatterChart().vm.$emit('chart-item-over', {
        traceId: mockResponse.traces[1].trace_id,
      });

      await findScatterChart().vm.$emit('chart-item-out');

      expect(findTableList().props('highlightedTraceId')).toBeNull();
    });
  });

  describe('error handling', () => {
    it('if fetchTraces fails, it renders an alert and empty list', async () => {
      observabilityClientMock.fetchTraces.mockRejectedValue('error');

      await mountComponent();

      expect(createAlert).toHaveBeenLastCalledWith({ message: 'Failed to load traces.' });
      expect(findTableList().exists()).toBe(true);
      expect(findTableList().props('traces')).toEqual([]);
    });
  });
});

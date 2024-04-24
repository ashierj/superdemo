import { GlLoadingIcon, GlInfiniteScroll, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import LogsTable from 'ee/logs/list/logs_table.vue';
import LogsDrawer from 'ee/logs/list/logs_drawer.vue';
import LogsFilteredSearch from 'ee/logs/list/filter_bar/logs_filtered_search.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LogsList from 'ee/logs/list/logs_list.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { mockLogs } from './mock_data';

jest.mock('~/alert');

describe('LogsList', () => {
  let wrapper;
  let observabilityClientMock;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findLogsTable = () => wrapper.findComponent(LogsTable);
  const findInfiniteScrolling = () => wrapper.findComponent(GlInfiniteScroll);
  const findInfiniteScrollingLegend = () =>
    findInfiniteScrolling().find('[data-testid="logs-infinite-scrolling-legend"]');

  const bottomReached = async () => {
    findInfiniteScrolling().vm.$emit('bottomReached');
    await waitForPromises();
  };

  const findDrawer = () => wrapper.findComponent(LogsDrawer);
  const isDrawerOpen = () => findDrawer().props('open');
  const getDrawerSelectedLog = () => findDrawer().props('log');

  const mountComponent = async () => {
    wrapper = shallowMountExtended(LogsList, {
      propsData: {
        observabilityClient: observabilityClientMock,
      },
      stubs: {
        GlSprintf,
      },
    });
    await waitForPromises();
  };

  beforeEach(() => {
    observabilityClientMock = {
      fetchLogs: jest.fn().mockResolvedValue({ logs: mockLogs, nextPageToken: 'page-2' }),
    };
  });

  it('renders the loading indicator while fetching logs', () => {
    mountComponent();

    expect(findLoadingIcon().exists()).toBe(true);
    expect(findLogsTable().exists()).toBe(false);
    expect(observabilityClientMock.fetchLogs).toHaveBeenCalled();
  });

  it('renders the LogsTable when fetching logs is done', async () => {
    await mountComponent();

    expect(findLoadingIcon().exists()).toBe(false);
    expect(findLogsTable().exists()).toBe(true);
    expect(findLogsTable().props('logs')).toEqual(mockLogs);
  });

  it('calls fetchLogs method when LogsTable emits reload event', async () => {
    await mountComponent();

    observabilityClientMock.fetchLogs.mockClear();

    findLogsTable().vm.$emit('reload');

    expect(observabilityClientMock.fetchLogs).toHaveBeenCalledTimes(1);
  });

  it('if fetchLogs fails, it renders an alert and empty list', async () => {
    observabilityClientMock.fetchLogs.mockRejectedValue('error');

    await mountComponent();

    expect(createAlert).toHaveBeenLastCalledWith({ message: 'Failed to load logs.' });
    expect(findLogsTable().exists()).toBe(true);
    expect(findLogsTable().props('logs')).toEqual([]);
  });

  describe('details drawer', () => {
    beforeEach(async () => {
      await mountComponent();
    });
    it('renders the details drawer initially closed', () => {
      expect(findDrawer().exists()).toBe(true);
      expect(isDrawerOpen()).toBe(false);
      expect(getDrawerSelectedLog()).toBe(null);
    });

    const selectLog = (logIndex) =>
      findLogsTable().vm.$emit('log-selected', { fingerprint: mockLogs[logIndex].fingerprint });

    it('opens the drawer and set the selected log, upond selection', async () => {
      await selectLog(1);

      expect(isDrawerOpen()).toBe(true);
      expect(getDrawerSelectedLog()).toEqual(mockLogs[1]);
    });

    it('closes the drawer upon receiving the close event', async () => {
      await selectLog(1);

      await findDrawer().vm.$emit('close');

      expect(isDrawerOpen()).toBe(false);
      expect(getDrawerSelectedLog()).toBe(null);
    });

    it('closes the drawer if the same log is selected', async () => {
      await selectLog(1);

      expect(isDrawerOpen()).toBe(true);

      await selectLog(1);

      expect(isDrawerOpen()).toBe(false);
    });

    it('changes the selected log and keeps the drawer open, upon selecting a different log', async () => {
      await selectLog(1);

      expect(isDrawerOpen()).toBe(true);

      await selectLog(2);

      expect(isDrawerOpen()).toBe(true);
      expect(getDrawerSelectedLog()).toEqual(mockLogs[2]);
    });

    it('handles invalid logs', async () => {
      await findLogsTable().vm.$emit('log-selected', { fingerprint: 'i-do-not-exist' });

      expect(isDrawerOpen()).toBe(false);
      expect(getDrawerSelectedLog()).toBe(null);
    });
  });

  describe('infinite scrolling / pagination', () => {
    describe('when data is returned', () => {
      beforeEach(async () => {
        await mountComponent();
      });

      it('renders the list with infinite scrolling', () => {
        const infiniteScrolling = findInfiniteScrolling();
        expect(infiniteScrolling.exists()).toBe(true);
        expect(infiniteScrolling.props('fetchedItems')).toBe(mockLogs.length);
        expect(infiniteScrolling.getComponent(LogsTable).exists()).toBe(true);
      });

      it('fetches the next page when bottom reached', async () => {
        const nextPageResponse = {
          logs: [{ fingerprint: 'log-1' }],
          next_page_token: 'page-3',
        };
        observabilityClientMock.fetchLogs.mockReturnValueOnce(nextPageResponse);

        await bottomReached();

        expect(observabilityClientMock.fetchLogs).toHaveBeenLastCalledWith({
          pageSize: 100,
          pageToken: 'page-2',
          filters: { dateRange: { value: '1h' }, attributes: {} },
        });

        expect(findInfiniteScrolling().props('fetchedItems')).toBe(
          mockLogs.length + nextPageResponse.logs.length,
        );
        expect(findLogsTable().props('logs')).toEqual([...mockLogs, ...nextPageResponse.logs]);
      });

      it('after reaching the last page, on bottom reached, it keeps fetching logs from the last available page', async () => {
        // Initial call from mounting
        expect(observabilityClientMock.fetchLogs).toHaveBeenCalledTimes(1);
        expect(observabilityClientMock.fetchLogs).toHaveBeenLastCalledWith({
          pageSize: 100,
          pageToken: null,
          filters: { dateRange: { value: '1h' }, attributes: {} },
        });

        // hit last page (no logs, no page token)
        observabilityClientMock.fetchLogs.mockReturnValue({
          logs: [],
        });
        await bottomReached();

        expect(observabilityClientMock.fetchLogs).toHaveBeenCalledTimes(2);
        expect(observabilityClientMock.fetchLogs).toHaveBeenLastCalledWith({
          pageSize: 100,
          pageToken: 'page-2',
          filters: { dateRange: { value: '1h' }, attributes: {} },
        });

        await bottomReached();

        expect(observabilityClientMock.fetchLogs).toHaveBeenCalledTimes(3);
        expect(observabilityClientMock.fetchLogs).toHaveBeenLastCalledWith({
          pageSize: 100,
          pageToken: 'page-2',
          filters: { dateRange: { value: '1h' }, attributes: {} },
        });
      });

      it('shows the number of fetched items as the legend', () => {
        expect(findInfiniteScrollingLegend().text()).toBe(`Showing ${mockLogs.length} logs`);
      });

      it('shows the spinner when fetching the next page', async () => {
        bottomReached();
        await nextTick();

        expect(findInfiniteScrolling().findComponent(GlLoadingIcon).exists()).toBe(true);
        expect(findInfiniteScrollingLegend().exists()).toBe(false);
      });
    });

    describe('when no data is returned', () => {
      beforeEach(async () => {
        observabilityClientMock.fetchLogs.mockReturnValue({
          logs: [],
        });
        await mountComponent();
      });

      // an empty legend is needed to override the default legend
      it('shows an empty legend when there are 0 items', () => {
        expect(findInfiniteScrollingLegend().text()).toBe('');
      });
    });
  });

  describe('filtered search', () => {
    beforeEach(async () => {
      await mountComponent();
    });

    const findFilteredSearch = () => wrapper.findComponent(LogsFilteredSearch);

    it('renders the FilteredSearch component', () => {
      expect(findFilteredSearch().exists()).toBe(true);
    });

    it('sets data-range-filter prop to the default date range', () => {
      expect(findFilteredSearch().props('dateRangeFilter')).toEqual({ value: '1h' });
    });

    it('fetches logs with default time range filter', () => {
      expect(observabilityClientMock.fetchLogs).toHaveBeenCalledWith({
        filters: {
          dateRange: {
            value: '1h',
          },
          attributes: {},
        },
        pageSize: 100,
        pageToken: null,
      });
    });

    describe('when filter changes', () => {
      beforeEach(async () => {
        observabilityClientMock.fetchLogs.mockReset();

        await findFilteredSearch().vm.$emit('filter', {
          dateRange: { value: '7d' },
          attributes: { search: [{ value: 'some-log' }] },
        });
        await waitForPromises();
      });

      it('fetches logs with the updated filters', () => {
        expect(observabilityClientMock.fetchLogs).toHaveBeenCalledTimes(1);
        expect(observabilityClientMock.fetchLogs).toHaveBeenLastCalledWith({
          filters: {
            dateRange: {
              value: '7d',
            },
            attributes: { search: [{ value: 'some-log' }] },
          },
          pageSize: 100,
          pageToken: null,
        });
      });

      it('updates the filtered search props', () => {
        expect(findFilteredSearch().props('dateRangeFilter')).toEqual({ value: '7d' });
        expect(findFilteredSearch().props('attributesFilters')).toEqual({
          search: [{ value: 'some-log' }],
        });
      });
    });
  });
});

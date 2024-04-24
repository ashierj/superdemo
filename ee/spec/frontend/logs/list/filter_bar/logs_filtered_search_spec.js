import { nextTick } from 'vue';
import DateRangeFilter from '~/observability/components/date_range_filter.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LogsFilteredSeach from 'ee/logs/list/filter_bar/logs_filtered_search.vue';
import { filterObjToFilterToken } from 'ee/logs/list/filter_bar/filters';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

describe('LogsFilteredSeach', () => {
  let wrapper;

  const defaultProps = {
    dateRangeFilter: {
      endDate: new Date('2020-07-06T00:00:00.000Z'),
      startDarte: new Date('2020-07-05T23:00:00.000Z'),
      value: '1h',
    },
    attributesFilters: {
      service: [{ operator: '=', value: 'serviceName' }],
      severityName: [{ operator: '!=', value: 'warning' }],
    },
  };

  const mount = (props = defaultProps) => {
    wrapper = shallowMountExtended(LogsFilteredSeach, {
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    mount();
  });

  const findDateRangeFilter = () => wrapper.findComponent(DateRangeFilter);
  const findFilteredSearch = () => wrapper.findComponent(FilteredSearch);

  describe('date range filter', () => {
    it('renders the date range filter', () => {
      expect(findDateRangeFilter().exists()).toBe(true);
    });

    it('sets the selected date range', () => {
      expect(findDateRangeFilter().props('selected')).toEqual(defaultProps.dateRangeFilter);
    });

    it('emits the filter event when the date range is changed', async () => {
      const dateRange = {
        value: '24h',
        startDate: new Date('2022-01-01'),
        endDate: new Date('2022-01-02'),
      };

      findDateRangeFilter().vm.$emit('onDateRangeSelected', dateRange);
      await nextTick();

      expect(wrapper.emitted('filter')).toEqual([
        [
          {
            dateRange,
            attributes: expect.any(Object),
          },
        ],
      ]);
      expect(findDateRangeFilter().props('selected')).toEqual(dateRange);
    });
  });

  describe('attributes filters', () => {
    it('renders the FilteredSearch', () => {
      expect(findFilteredSearch().exists()).toBe(true);
    });

    it('sets the initial attributes filter by converting it to tokens', () => {
      expect(findFilteredSearch().props('initialFilterValue')).toEqual(
        filterObjToFilterToken(defaultProps.attributesFilters),
      );
    });

    it('emits the filter event when the search is submitted', async () => {
      const filterObj = {
        search: [{ value: 'some-search' }],
        fingerprint: [{ operator: '=', value: 'fingerprint' }],
      };

      const filterTokens = filterObjToFilterToken(filterObj);

      findFilteredSearch().vm.$emit('onFilter', filterTokens);
      await nextTick();

      expect(wrapper.emitted('filter')).toEqual([
        [
          {
            dateRange: expect.any(Object),
            attributes: filterObj,
          },
        ],
      ]);
      expect(findFilteredSearch().props('initialFilterValue')).toEqual(filterTokens);
    });
  });
});

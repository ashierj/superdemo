import { GlFilteredSearchToken } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MetricsFilteredSearch from 'ee/metrics/details/filter_bar/metrics_filtered_search.vue';
import DateRangeFilter from 'ee/metrics/details/filter_bar/date_range_filter.vue';
import GroupByFilter from 'ee/metrics/details/filter_bar/groupby_filter.vue';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { OPERATORS_IS_NOT } from '~/vue_shared/components/filtered_search_bar/constants';
import { OPERATORS_LIKE_NOT } from '~/observability/constants';

describe('MetricsFilteredSearch', () => {
  let wrapper;

  const defaultSearchConfig = {
    dimensions: ['dimension_one', 'dimension_two'],
    groupByFunctions: ['avg', 'sum', 'p50'],
  };

  const mount = (props = {}, searchConfig = {}) => {
    wrapper = shallowMountExtended(MetricsFilteredSearch, {
      propsData: {
        searchConfig: { ...defaultSearchConfig, ...searchConfig },
        ...props,
      },
    });
  };

  beforeEach(() => {
    mount();
  });

  const findFilteredSearch = () => wrapper.findComponent(FilteredSearch);
  const findDateRangeFilter = () => wrapper.findComponent(DateRangeFilter);
  const findGroupByFilter = () => wrapper.findComponent(GroupByFilter);

  it('renders the filtered search component with tokens based on dimensions', () => {
    const filteredSeach = findFilteredSearch();
    expect(filteredSeach.exists()).toBe(true);
    const tokens = filteredSeach.props('tokens');
    expect(tokens.length).toBe(defaultSearchConfig.dimensions.length);
    tokens.forEach((token, index) => {
      expect(token.type).toBe(defaultSearchConfig.dimensions[index]);
      expect(token.title).toBe(defaultSearchConfig.dimensions[index]);
      expect(token.token).toBe(GlFilteredSearchToken);
      expect(token.operators).toEqual([...OPERATORS_IS_NOT, ...OPERATORS_LIKE_NOT]);
    });
  });

  it('renders the filtered search component with with initial tokens', () => {
    const filters = [{ type: 'key.name', value: 'foo' }];
    mount({ dimensionFilters: filters });

    expect(findFilteredSearch().props('initialFilterValue')).toEqual(filters);
  });

  it('renders the date range picker dropdown with the selected date range', () => {
    const date = {
      endDate: new Date('2020-07-06T00:00:00.000Z'),
      startDarte: new Date('2020-07-05T23:00:00.000Z'),
      value: '1h',
    };
    mount({ dateRangeFilter: date });
    const dateRangesDropdown = findDateRangeFilter();
    expect(dateRangesDropdown.exists()).toBe(true);
    expect(dateRangesDropdown.props('selected')).toEqual(date);
  });

  describe('group-by filter', () => {
    it('renders the group-by filter with search config', () => {
      const groupBy = findGroupByFilter();
      expect(groupBy.exists()).toBe(true);
      expect(groupBy.props('searchConfig')).toEqual(defaultSearchConfig);
      expect(groupBy.props('selectedFunction')).toBe('');
      expect(groupBy.props('selectedDimensions')).toEqual([]);
    });

    it('renders the group-by filter with defaults', () => {
      mount(
        {},
        {
          defaultGroupByFunction: 'avg',
          defaultGroupByDimensions: ['dimension_one', 'dimension_two'],
        },
      );
      const groupBy = findGroupByFilter();

      expect(groupBy.props('searchConfig')).toEqual({
        ...defaultSearchConfig,
        defaultGroupByFunction: 'avg',
        defaultGroupByDimensions: ['dimension_one', 'dimension_two'],
      });

      expect(groupBy.props('selectedFunction')).toBe('avg');
      expect(groupBy.props('selectedDimensions')).toEqual(['dimension_one', 'dimension_two']);
    });

    it('renders the group-by filter with specified prop', () => {
      mount(
        {
          groupByFilter: {
            func: 'sum',
            dimensions: ['attr_1'],
          },
        },
        {
          defaultGroupByFunction: 'avg',
          defaultGroupByDimensions: ['dimension_one', 'dimension_two'],
        },
      );
      const groupBy = findGroupByFilter();

      expect(groupBy.props('selectedFunction')).toBe('sum');
      expect(groupBy.props('selectedDimensions')).toEqual(['attr_1']);
    });
  });

  it('emits the filter event when the dimensions filter is changed', async () => {
    const filters = [{ dimension: 'namespace', operator: 'is not', value: 'test' }];
    await findFilteredSearch().vm.$emit('onFilter', filters);

    expect(wrapper.emitted('filter')).toEqual([
      [
        {
          dimensions: [{ dimension: 'namespace', operator: 'is not', value: 'test' }],
          groupBy: {
            dimensions: [],
            func: '',
          },
        },
      ],
    ]);
  });

  it('emits the filter event when the date range is changed and the filtered-search onFilter is emitted', async () => {
    const dateRange = {
      value: '24h',
      startDate: new Date('2022-01-01'),
      endDate: new Date('2022-01-02'),
    };

    await findDateRangeFilter().vm.$emit('onDateRangeSelected', dateRange);
    expect(wrapper.emitted('filter')).toBeUndefined();

    await findFilteredSearch().vm.$emit('onFilter', []);

    expect(wrapper.emitted('filter')).toEqual([
      [
        {
          dimensions: [],
          dateRange,
          groupBy: {
            dimensions: [],
            func: '',
          },
        },
      ],
    ]);
    expect(findDateRangeFilter().props('selected')).toEqual(dateRange);
  });

  it('emits the filter event with default group-by when onFilter is emitted', async () => {
    mount(
      {},
      {
        defaultGroupByFunction: 'avg',
        defaultGroupByDimensions: ['dimension_one', 'dimension_two'],
      },
    );

    await findFilteredSearch().vm.$emit('onFilter', []);

    expect(wrapper.emitted('filter')).toEqual([
      [
        {
          dimensions: [],
          groupBy: {
            dimensions: ['dimension_one', 'dimension_two'],
            func: 'avg',
          },
        },
      ],
    ]);
  });

  it('emits the filter event when the group-by is changed and the filtered-search onFilter is emitted', async () => {
    const groupBy = {
      dimensions: ['dimension_one'],
      func: 'sum',
    };

    await findGroupByFilter().vm.$emit('groupBy', groupBy);
    expect(wrapper.emitted('filter')).toBeUndefined();

    await findFilteredSearch().vm.$emit('onFilter', []);

    expect(wrapper.emitted('filter')).toEqual([
      [
        {
          dimensions: [],
          groupBy,
        },
      ],
    ]);
    expect(findGroupByFilter().props('selectedFunction')).toBe(groupBy.func);
    expect(findGroupByFilter().props('selectedDimensions')).toEqual(groupBy.dimensions);
  });
});

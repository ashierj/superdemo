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

  const defaultSearchMetadata = {
    name: 'cpu_seconds_total',
    type: 'sum',
    description: 'some_description',
    last_ingested_at: 1705374438711900000,
    attribute_keys: ['attribute_one', 'attribute_two'],
    supported_aggregations: ['1m', '1h'],
    supported_functions: ['avg', 'sum', 'p50'],
    default_group_by_attributes: ['host.name'],
    default_group_by_function: 'avg',
  };

  const mount = (props = {}, searchMetadata = {}) => {
    wrapper = shallowMountExtended(MetricsFilteredSearch, {
      propsData: {
        searchMetadata: { ...defaultSearchMetadata, ...searchMetadata },
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

  it('renders the filtered search component with tokens based on attributes', () => {
    const filteredSeach = findFilteredSearch();
    expect(filteredSeach.exists()).toBe(true);
    const tokens = filteredSeach.props('tokens');
    expect(tokens.length).toBe(defaultSearchMetadata.attribute_keys.length);
    tokens.forEach((token, index) => {
      expect(token.type).toBe(defaultSearchMetadata.attribute_keys[index]);
      expect(token.title).toBe(defaultSearchMetadata.attribute_keys[index]);
      expect(token.token).toBe(GlFilteredSearchToken);
      expect(token.operators).toEqual([...OPERATORS_IS_NOT, ...OPERATORS_LIKE_NOT]);
    });
  });

  it('renders the filtered search component with with initial tokens', () => {
    const filters = [{ type: 'key.name', value: 'foo' }];

    mount({ attributeFilters: filters });

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
    it('renders the group-by filter with search metadata', () => {
      const groupBy = findGroupByFilter();
      expect(groupBy.exists()).toBe(true);
      expect(groupBy.props('supportedAttributes')).toEqual(defaultSearchMetadata.attribute_keys);
      expect(groupBy.props('supportedFunctions')).toEqual(
        defaultSearchMetadata.supported_functions,
      );
      expect(groupBy.props('selectedFunction')).toBe(
        defaultSearchMetadata.default_group_by_function,
      );
      expect(groupBy.props('selectedAttributes')).toEqual(
        defaultSearchMetadata.default_group_by_attributes,
      );
    });

    it('renders the group-by filter with selected values', () => {
      mount({
        groupByFilter: {
          func: 'sum',
          attributes: ['attribute_one'],
        },
      });

      const groupBy = findGroupByFilter();
      expect(groupBy.props('selectedFunction')).toBe('sum');
      expect(groupBy.props('selectedAttributes')).toEqual(['attribute_one']);
    });

    it(`handles default_group_by_attributes=['*']`, () => {
      mount({
        searchMetadata: {
          ...defaultSearchMetadata,
          default_group_by_attributes: ['*'],
        },
      });

      expect(findGroupByFilter().props('selectedAttributes')).toEqual([
        ...defaultSearchMetadata.attribute_keys,
      ]);
    });
  });

  it('emits the filter event when the attributes filter is changed', async () => {
    const filters = [{ attribute: 'namespace', operator: 'is not', value: 'test' }];

    await findFilteredSearch().vm.$emit('onFilter', filters);

    expect(wrapper.emitted('filter')).toEqual([
      [
        {
          attributes: [{ attribute: 'namespace', operator: 'is not', value: 'test' }],
          groupBy: {
            attributes: defaultSearchMetadata.default_group_by_attributes,
            func: defaultSearchMetadata.default_group_by_function,
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
          attributes: [],
          dateRange,
          groupBy: {
            attributes: defaultSearchMetadata.default_group_by_attributes,
            func: defaultSearchMetadata.default_group_by_function,
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
        default_group_by_function: 'avg',
        default_group_by_attributes: ['attribute_one', 'attribute_two'],
      },
    );
    await findFilteredSearch().vm.$emit('onFilter', []);

    expect(wrapper.emitted('filter')).toEqual([
      [
        {
          attributes: [],
          groupBy: {
            attributes: ['attribute_one', 'attribute_two'],
            func: 'avg',
          },
        },
      ],
    ]);
  });

  it('emits the filter event when the group-by is changed and the filtered-search onFilter is emitted', async () => {
    const groupBy = {
      attributes: ['attribute_one'],
      func: 'sum',
    };

    await findGroupByFilter().vm.$emit('groupBy', groupBy);

    expect(wrapper.emitted('filter')).toBeUndefined();

    await findFilteredSearch().vm.$emit('onFilter', []);

    expect(wrapper.emitted('filter')).toEqual([
      [
        {
          attributes: [],
          groupBy,
        },
      ],
    ]);
    expect(findGroupByFilter().props('selectedFunction')).toBe(groupBy.func);
    expect(findGroupByFilter().props('selectedAttributes')).toEqual(groupBy.attributes);
  });
});

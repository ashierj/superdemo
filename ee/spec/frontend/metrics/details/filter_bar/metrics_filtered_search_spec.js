import { GlFilteredSearchToken } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MetricsFilteredSearch from 'ee/metrics/details/filter_bar/metrics_filtered_search.vue';
import DateRangeFilter from 'ee/metrics/details/filter_bar/date_range_filter.vue';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { OPERATORS_IS_NOT } from '~/vue_shared/components/filtered_search_bar/constants';
import { OPERATORS_LIKE_NOT } from '~/observability/constants';

describe('MetricsFilteredSearch', () => {
  let wrapper;

  const dimensions = ['dimension_one', 'dimension_two'];

  beforeEach(() => {
    wrapper = shallowMountExtended(MetricsFilteredSearch, {
      propsData: {
        dimensions,
      },
    });
  });

  const findFilteredSearch = () => wrapper.findComponent(FilteredSearch);
  const findDateRangeFilter = () => wrapper.findComponent(DateRangeFilter);

  it('renders the filtered search component with tokens based on dimensions', () => {
    const filteredSeach = findFilteredSearch();
    expect(filteredSeach.exists()).toBe(true);
    const tokens = filteredSeach.props('tokens');
    expect(tokens.length).toBe(dimensions.length);
    tokens.forEach((token, index) => {
      expect(token.type).toBe(dimensions[index]);
      expect(token.title).toBe(dimensions[index]);
      expect(token.token).toBe(GlFilteredSearchToken);
      expect(token.operators).toEqual([...OPERATORS_IS_NOT, ...OPERATORS_LIKE_NOT]);
    });
  });

  it('renders the date range picker dropdown with the default date range', () => {
    const dateRangesDropdown = findDateRangeFilter();
    expect(dateRangesDropdown.exists()).toBe(true);
    expect(dateRangesDropdown.props('selected')).toEqual({
      endDate: new Date('2020-07-06T00:00:00.000Z'),
      startDarte: new Date('2020-07-05T23:00:00.000Z'),
      value: '1h',
    });
  });

  it('emits the filter event when the dimensions filter is changed', async () => {
    const filters = [{ dimension: 'namespace', operator: 'is not', value: 'test' }];
    await findFilteredSearch().vm.$emit('onFilter', filters);
    expect(wrapper.emitted('filter')).toEqual([
      [
        {
          dimensions: [{ dimension: 'namespace', operator: 'is not', value: 'test' }],
          dateRange: {
            endDate: new Date('2020-07-06T00:00:00.000Z'),
            startDarte: new Date('2020-07-05T23:00:00.000Z'),
            value: '1h',
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

    expect(wrapper.emitted('filter')).toEqual([[{ dimensions: [], dateRange }]]);
    expect(findDateRangeFilter().props('selected')).toEqual(dateRange);
  });
});

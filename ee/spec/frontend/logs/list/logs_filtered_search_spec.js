import { nextTick } from 'vue';
import DateRangeFilter from '~/observability/components/date_range_filter.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LogsFilteredSeach from 'ee/logs/list/filter_bar/logs_filtered_search.vue';

describe('LogsFilteredSeach', () => {
  let wrapper;

  const defaultProps = {
    dateRangeFilter: {
      endDate: new Date('2020-07-06T00:00:00.000Z'),
      startDarte: new Date('2020-07-05T23:00:00.000Z'),
      value: '1h',
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

  it('renders the date range filter', () => {
    expect(findDateRangeFilter().exists()).toBe(true);
  });

  it('sets the selected date range', () => {
    expect(findDateRangeFilter().props('selected')).toEqual(defaultProps.dateRangeFilter);
  });

  it('emits the filter event when the date range is changed and submit button is clicked', async () => {
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
        },
      ],
    ]);
    expect(findDateRangeFilter().props('selected')).toEqual(dateRange);
  });
});

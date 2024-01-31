import { GlDaterangePicker } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DateRangesDropdown from '~/analytics/shared/components/date_ranges_dropdown.vue';
import DateRangeFilter from 'ee/metrics/details/filter_bar/date_range_filter.vue';

describe('DateRangeFilter', () => {
  let wrapper;

  const defaultTimeRange = {
    value: '1h',
    startDate: new Date(),
    endDate: new Date(),
  };

  const mount = (selected) => {
    wrapper = shallowMountExtended(DateRangeFilter, {
      propsData: {
        selected,
      },
    });
  };

  beforeEach(() => {
    mount(defaultTimeRange);
  });

  const findDateRangesDropdown = () => wrapper.findComponent(DateRangesDropdown);
  const findDateRangesPicker = () => wrapper.findComponent(GlDaterangePicker);

  it('renders the date ranges dropdown with the default selected value and options', () => {
    const dateRangesDropdown = findDateRangesDropdown();
    expect(dateRangesDropdown.exists()).toBe(true);
    expect(dateRangesDropdown.props('selected')).toBe(defaultTimeRange.value);
    expect(dateRangesDropdown.props('dateRangeOptions')).toMatchInlineSnapshot(`
      Array [
        Object {
          "endDate": 2020-07-06T00:00:00.000Z,
          "startDate": 2020-07-05T23:55:00.000Z,
          "text": "Last 5 minutes",
          "value": "5m",
        },
        Object {
          "endDate": 2020-07-06T00:00:00.000Z,
          "startDate": 2020-07-05T23:45:00.000Z,
          "text": "Last 15 minutes",
          "value": "15m",
        },
        Object {
          "endDate": 2020-07-06T00:00:00.000Z,
          "startDate": 2020-07-05T23:30:00.000Z,
          "text": "Last 30 minutes",
          "value": "30m",
        },
        Object {
          "endDate": 2020-07-06T00:00:00.000Z,
          "startDate": 2020-07-05T23:00:00.000Z,
          "text": "Last 1 hour",
          "value": "1h",
        },
        Object {
          "endDate": 2020-07-06T00:00:00.000Z,
          "startDate": 2020-07-05T20:00:00.000Z,
          "text": "Last 4 hours",
          "value": "4h",
        },
        Object {
          "endDate": 2020-07-06T00:00:00.000Z,
          "startDate": 2020-07-05T12:00:00.000Z,
          "text": "Last 12 hours",
          "value": "12h",
        },
        Object {
          "endDate": 2020-07-06T00:00:00.000Z,
          "startDate": 2020-07-05T00:00:00.000Z,
          "text": "Last 24 hours",
          "value": "24h",
        },
        Object {
          "endDate": 2020-07-06T00:00:00.000Z,
          "startDate": 2020-06-29T00:00:00.000Z,
          "text": "Last 7 days",
          "value": "7d",
        },
        Object {
          "endDate": 2020-07-06T00:00:00.000Z,
          "startDate": 2020-06-22T00:00:00.000Z,
          "text": "Last 14 days",
          "value": "14d",
        },
        Object {
          "endDate": 2020-07-06T00:00:00.000Z,
          "startDate": 2020-06-06T00:00:00.000Z,
          "text": "Last 30 days",
          "value": "30d",
        },
      ]
    `);
  });

  it('does not set the selected value if not specified', () => {
    mount(undefined);
    expect(findDateRangesDropdown().props('selected')).toBe('');
  });

  it('renders the daterange-picker with default 30d date range when customDateRangeSelected is emitteed', async () => {
    expect(findDateRangesPicker().exists()).toBe(false);
    await findDateRangesDropdown().vm.$emit('customDateRangeSelected');
    expect(findDateRangesPicker().exists()).toBe(true);
    // mocked 30d date range
    expect(findDateRangesPicker().props('defaultStartDate')).toEqual(new Date('2020-06-06'));
    expect(findDateRangesPicker().props('defaultEndDate')).toEqual(new Date('2020-07-06'));
  });

  it('renders the daterange-picker if custom option is selected', () => {
    const timeRange = {
      startDate: new Date('2022-01-01'),
      endDate: new Date('2022-01-02'),
    };
    mount({ value: 'custom', startDate: timeRange.startDate, endDate: timeRange.endDate });
    expect(findDateRangesPicker().exists()).toBe(true);
    expect(findDateRangesPicker().props('defaultStartDate')).toBe(timeRange.startDate);
    expect(findDateRangesPicker().props('defaultEndDate')).toBe(timeRange.endDate);
  });

  it('emits the onDateRangeSelected event when the time range is selected', async () => {
    const timeRange = {
      value: '24h',
      startDate: new Date('2022-01-01'),
      endDate: new Date('2022-01-02'),
    };
    await findDateRangesDropdown().vm.$emit('selected', timeRange);
    expect(wrapper.emitted('onDateRangeSelected')).toEqual([[{ ...timeRange }]]);
  });

  it('emits the onDateRangeSelected event when a custom time range is selected', async () => {
    const defaultCustomTimeRange = {
      // last30d
      endDate: new Date('2020-07-06T00:00:00.000Z'),
      startDate: new Date('2020-06-06T00:00:00.000Z'),
    };
    const timeRange = {
      startDate: new Date('2021-01-01'),
      endDate: new Date('2021-01-02'),
    };
    await findDateRangesDropdown().vm.$emit('customDateRangeSelected');
    expect(wrapper.emitted('onDateRangeSelected')).toEqual([
      [
        {
          ...defaultCustomTimeRange,
          value: 'custom',
        },
      ],
    ]);
    await findDateRangesPicker().vm.$emit('input', timeRange);
    expect(wrapper.emitted('onDateRangeSelected')).toEqual([
      [
        {
          ...defaultCustomTimeRange,
          value: 'custom',
        },
      ],
      [
        {
          ...timeRange,
          value: 'custom',
        },
      ],
    ]);
  });
});

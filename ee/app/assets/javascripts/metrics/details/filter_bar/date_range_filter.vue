<script>
import { GlDaterangePicker } from '@gitlab/ui';
import { periodToDate } from '~/observability/utils';
import DateRangesDropdown from '~/analytics/shared/components/date_ranges_dropdown.vue';
import { TIME_RANGE_OPTIONS } from '~/observability/constants';

export default {
  components: {
    DateRangesDropdown,
    GlDaterangePicker,
  },
  props: {
    selected: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      shouldShowDateRangePicker: false,
      dateRange: this.selected ?? {
        value: '',
        min: null,
        max: null,
      },
    };
  },
  computed: {
    dateRangeOptions() {
      return TIME_RANGE_OPTIONS.map((option) => {
        const dateRange = periodToDate(option.value);
        return {
          value: option.value,
          text: option.title,
          startDate: dateRange.min,
          endDate: dateRange.max,
        };
      });
    },
  },
  methods: {
    onSelectPredefinedDateRange({ value, startDate, endDate }) {
      this.shouldShowDateRangePicker = false;
      this.dateRange = {
        value,
        startDate: new Date(startDate),
        endDate: new Date(endDate),
      };
      this.$emit('onDateRangeSelected', this.dateRange);
    },
    onSelectCustomDateRange() {
      this.shouldShowDateRangePicker = true;
    },
    onCustomRangeSelected({ startDate, endDate }) {
      this.dateRange = {
        value: 'custom',
        startDate: new Date(startDate),
        endDate: new Date(endDate),
      };
      this.$emit('onDateRangeSelected', this.dateRange);
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-column gl-lg-flex-direction-row gl-gap-3">
    <date-ranges-dropdown
      :selected="dateRange.value"
      :date-range-options="dateRangeOptions"
      disable-selected-day-count
      tooltip=""
      include-end-date-in-days-selected
      @selected="onSelectPredefinedDateRange"
      @customDateRangeSelected="onSelectCustomDateRange"
    />
    <gl-daterange-picker
      v-if="shouldShowDateRangePicker"
      start-opened
      @input="onCustomRangeSelected"
    />
  </div>
</template>

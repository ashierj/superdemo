<script>
import DateRangeFilter from '~/observability/components/date_range_filter.vue';

export default {
  components: {
    DateRangeFilter,
  },
  props: {
    dateRangeFilter: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      dateRange: this.dateRangeFilter,
    };
  },
  methods: {
    onDateRangeSelected({ value, startDate, endDate }) {
      this.dateRange = { value, startDate, endDate };
      this.$emit('filter', { dateRange: this.dateRange });
    },
  },
};
</script>

<template>
  <div
    class="gl-py-5 gl-px-3 gl-bg-gray-10 gl-border-b-1 gl-border-b-solid gl-border-t-1 gl-border-t-solid gl-border-gray-100"
  >
    <date-range-filter :selected="dateRange" @onDateRangeSelected="onDateRangeSelected" />
  </div>
</template>

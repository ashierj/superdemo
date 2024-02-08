<script>
import { formatNumber, s__ } from '~/locale';
import { formatDate } from '~/lib/utils/datetime/date_format_utility';
import { SHORT_DATE_FORMAT } from '~/vue_shared/constants';

import StatisticsCard from '../../../components/statistics_card.vue';
import { getCurrentMonth } from '../utils';

export default {
  name: 'ProductAnalyticsGroupUsageOverview',
  components: { StatisticsCard },
  props: {
    eventsUsed: {
      type: Number,
      required: false,
      default: null,
    },
    storedEventsLimit: {
      type: Number,
      required: false,
      default: null,
    },
    isLoading: {
      type: Boolean,
      required: false,
    },
  },
  computed: {
    description() {
      const currentMonth = getCurrentMonth();
      return s__(`Analytics|Events received since ${formatDate(currentMonth, SHORT_DATE_FORMAT)}`);
    },
    eventsUsedPercentage() {
      if (!this.storedEventsLimit) {
        return 100;
      }

      const used = Math.floor((this.eventsUsed / this.storedEventsLimit) * 100);

      return Math.min(used, 100);
    },
    formattedEventsUsed() {
      return formatNumber(this.eventsUsed);
    },
    formattedStoredEventsLimit() {
      return formatNumber(this.storedEventsLimit);
    },
    showStatisticsCard() {
      return this.isLoading || this.storedEventsLimit !== null;
    },
  },
};
</script>

<template>
  <statistics-card
    v-if="showStatisticsCard"
    :loading="isLoading"
    :usage-value="formattedEventsUsed"
    :total-value="formattedStoredEventsLimit"
    :description="description"
    :percentage="eventsUsedPercentage"
  />
</template>

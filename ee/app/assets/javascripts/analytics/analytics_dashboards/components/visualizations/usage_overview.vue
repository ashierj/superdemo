<script>
import { compact } from 'lodash';
import { s__, sprintf } from '~/locale';
import dateFormat, { masks } from '~/lib/dateformat';
import SingleStat from './single_stat.vue';

export default {
  name: 'UsageOverview',
  components: {
    SingleStat,
  },
  props: {
    data: {
      type: Array,
      required: true,
    },
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    recordedAt() {
      const allRecordedAt = compact(this.data.map((metric) => metric.recordedAt));
      const [mostRecentRecordedAt] = allRecordedAt.sort().slice(-1);

      if (!mostRecentRecordedAt) return null;

      return dateFormat(mostRecentRecordedAt, `${masks.isoDate} ${masks.shortTime}`);
    },
  },
  mounted() {
    const { recordedAt } = this;
    const { tooltip, lastUpdated } = this.$options.i18n;
    const text = `${tooltip}${recordedAt ? sprintf(lastUpdated, { recordedAt }) : ''}`;
    this.$emit('showTooltip', text);
  },
  i18n: {
    tooltip: s__(
      'Analytics|Statistics on top-level namespace usage. Usage data is a cumulative count, and updated monthly.',
    ),
    lastUpdated: s__('Analytics| Last updated: %{recordedAt}'),
  },
};
</script>
<template>
  <div class="gl-display-flex gl-md-flex-direction-column gl-flex-direction-row gl-font-size-sm">
    <div v-for="metric in data" :key="metric.identifier" class="gl-pr-9">
      <single-stat :data="metric.value" :options="metric.options" />
    </div>
  </div>
</template>

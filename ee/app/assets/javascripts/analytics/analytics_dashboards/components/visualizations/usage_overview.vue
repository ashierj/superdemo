<script>
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
};
</script>
<template>
  <div class="gl-display-flex gl-md-flex-direction-column gl-flex-direction-row gl-font-size-sm">
    <div v-for="metric in data" :key="metric.identifier" class="gl-pr-9">
      <single-stat :data="metric.value" :options="metric.options" />
    </div>
  </div>
</template>

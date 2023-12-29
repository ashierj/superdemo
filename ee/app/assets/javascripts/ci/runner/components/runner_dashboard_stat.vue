<script>
import { formatNumber } from '~/locale';
import { INSTANCE_TYPE } from '~/ci/runner/constants';
import RunnerCount from '~/ci/runner/components/stat/runner_count.vue';

export default {
  name: 'RunnerDashboardStat',
  components: {
    RunnerCount,
  },
  props: {
    variables: {
      type: Object,
      required: true,
    },
  },
  methods: {
    formattedValue(value) {
      if (typeof value === 'number') {
        return formatNumber(value);
      }
      return '-';
    },
  },
  INSTANCE_TYPE,
};
</script>

<template>
  <div class="gl-border gl-rounded-base gl-p-5">
    <h2 class="gl-font-lg gl-mt-0">
      <slot name="title"></slot>
    </h2>
    <runner-count #default="{ count }" :scope="$options.INSTANCE_TYPE" :variables="variables">
      <span class="gl-font-weight-bold gl-font-size-h-display">{{ formattedValue(count) }}</span>
    </runner-count>
  </div>
</template>

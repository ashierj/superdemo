<script>
import { GlIcon } from '@gitlab/ui';
import { I18N_STATUS_ONLINE, STATUS_ONLINE } from '~/ci/runner/constants';
import RunnerDashboardStat from './runner_dashboard_stat.vue';

export default {
  name: 'RunnerDashboardStatOnline',
  components: {
    GlIcon,
    RunnerDashboardStat,
  },
  I18N_STATUS_ONLINE,
  STATUS_ONLINE,
};
</script>

<template>
  <runner-dashboard-stat :variables="{ status: $options.STATUS_ONLINE }">
    <template #title>
      <gl-icon class="gl-text-green-500" :size="12" name="status-active" />
      {{ $options.I18N_STATUS_ONLINE }}
    </template>
  </runner-dashboard-stat>
</template>

<script>
import { GlIcon } from '@gitlab/ui';
import { I18N_STATUS_OFFLINE, STATUS_OFFLINE } from '~/ci/runner/constants';
import RunnerDashboardStat from './runner_dashboard_stat.vue';

export default {
  name: 'RunnerDashboardStatOffline',
  components: {
    GlIcon,
    RunnerDashboardStat,
  },
  I18N_STATUS_OFFLINE,
  STATUS_OFFLINE,
};
</script>

<template>
  <runner-dashboard-stat :variables="{ status: $options.STATUS_OFFLINE }">
    <template #title>
      <gl-icon class="gl-text-gray-500" :size="12" name="status-waiting" />
      {{ $options.I18N_STATUS_OFFLINE }}
    </template>
  </runner-dashboard-stat>
</template>

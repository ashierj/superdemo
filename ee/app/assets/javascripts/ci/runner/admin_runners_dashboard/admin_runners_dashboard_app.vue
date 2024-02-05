<script>
import { GlButton } from '@gitlab/ui';
import RunnerListHeader from '~/ci/runner/components/runner_list_header.vue';
import RunnerDashboardStatOnline from '../components/runner_dashboard_stat_online.vue';
import RunnerDashboardStatOffline from '../components/runner_dashboard_stat_offline.vue';
import RunnerUsage from '../components/runner_usage.vue';
import RunnerJobFailures from '../components/runner_job_failures.vue';
import RunnerActiveList from '../components/runner_active_list.vue';
import RunnerWaitTimes from '../components/runner_wait_times.vue';

export default {
  components: {
    GlButton,
    RunnerListHeader,
    RunnerDashboardStatOnline,
    RunnerDashboardStatOffline,
    RunnerUsage,
    RunnerJobFailures,
    RunnerActiveList,
    RunnerWaitTimes,
  },
  props: {
    adminRunnersPath: {
      type: String,
      required: true,
    },
    newRunnerPath: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div>
    <runner-list-header>
      <template #title>{{ s__('Runners|Fleet dashboard') }}</template>
      <template #actions>
        <gl-button variant="link" :href="adminRunnersPath">{{
          s__('Runners|View runners list')
        }}</gl-button>
        <gl-button variant="confirm" :href="newRunnerPath">
          {{ s__('Runners|New instance runner') }}
        </gl-button>
      </template>
    </runner-list-header>

    <p>
      {{ s__('Runners|Use the dashboard to view performance statistics of your runner fleet.') }}
    </p>

    <div>
      <div class="gl-sm-display-flex gl-gap-4 gl-justify-content-space-between">
        <runner-dashboard-stat-online
          class="runners-dashboard-third-gap-4 gl-flex-grow-1 gl-mb-4"
        />
        <runner-dashboard-stat-offline
          class="runners-dashboard-third-gap-4 gl-flex-grow-1 gl-mb-4"
        />
        <runner-usage class="runners-dashboard-third-gap-4 gl-flex-grow-1 gl-mb-4" />
      </div>

      <div class="gl-md-display-flex gl-gap-4 gl-justify-content-space-between">
        <runner-job-failures class="runners-dashboard-two-thirds-gap-4 gl-flex-grow-1 gl-mb-4" />
        <runner-active-list class="runners-dashboard-third-gap-4 gl-flex-grow-1 gl-mb-4" />
      </div>

      <runner-wait-times class="runners-dashboard-wait-times" />
    </div>
  </div>
</template>

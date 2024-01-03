<script>
import { GlButton } from '@gitlab/ui';
import RunnerListHeader from '~/ci/runner/components/runner_list_header.vue';
import RunnerDashboardStatusOnline from '../components/runner_dashboard_stat_online.vue';
import RunnerDashboardStatusOffline from '../components/runner_dashboard_stat_offline.vue';
import RunnerUsage from '../components/runner_usage.vue';
import RunnerJobFailures from '../components/runner_job_failures.vue';
import RunnerActiveList from '../components/runner_active_list.vue';
import RunnerWaitTimes from '../components/runner_wait_times.vue';

export default {
  components: {
    GlButton,
    RunnerListHeader,
    RunnerDashboardStatusOnline,
    RunnerDashboardStatusOffline,
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
    clickhouseCiAnalyticsAvailable: {
      type: Boolean,
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

    <div class="runners-dashboard-grid">
      <!-- 1st row -->
      <runner-dashboard-status-online />
      <runner-dashboard-status-offline />
      <runner-usage />

      <!-- 2nd row -->
      <runner-job-failures class="runners-dashboard-failures" />
      <runner-active-list class="runners-dashboard-active-list" />

      <!-- 3rd row -->
      <runner-wait-times
        class="runners-dashboard-wait-times"
        :clickhouse-ci-analytics-available="clickhouseCiAnalyticsAvailable"
      />
    </div>
  </div>
</template>

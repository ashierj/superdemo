<script>
import { GlButton } from '@gitlab/ui';
import RunnerListHeader from '~/ci/runner/components/runner_list_header.vue';
import RunnerJobFailures from '../components/runner_job_failures.vue';
import RunnerActiveList from '../components/runner_active_list.vue';
import RunnerWaitTimes from '../components/runner_wait_times.vue';

export default {
  components: {
    GlButton,
    RunnerListHeader,
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

    <div class="gl-md-display-flex gl-gap-3">
      <runner-job-failures class="gl-flex-grow-2 gl-flex-basis-0 gl-mb-3" />
      <runner-active-list class="gl-flex-grow-1 gl-flex-basis-0 gl-mb-3" />
    </div>
    <div class="gl-md-display-flex">
      <runner-wait-times class="gl-flex-grow-1 gl-flex-basis-0 gl-mb-3" />
    </div>
  </div>
</template>

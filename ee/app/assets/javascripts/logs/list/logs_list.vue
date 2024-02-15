<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import LogsTable from './logs_table.vue';

export default {
  components: {
    GlLoadingIcon,
    LogsTable,
  },
  props: {
    observabilityClient: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      loading: false,
      logs: [],
    };
  },
  created() {
    this.fetchLogs();
  },
  methods: {
    async fetchLogs() {
      this.loading = true;
      try {
        this.logs = await this.observabilityClient.fetchLogs();
      } catch {
        createAlert({
          message: s__('ObservabilityLogs|Failed to load logs.'),
        });
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <div>
    <div v-if="loading" class="gl-py-5">
      <gl-loading-icon size="lg" />
    </div>

    <div v-else class="gl-m-7">
      <logs-table :logs="logs" @reload="fetchLogs" />
    </div>
  </div>
</template>

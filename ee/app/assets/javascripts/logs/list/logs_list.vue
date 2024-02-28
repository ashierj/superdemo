<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import LogsTable from './logs_table.vue';
import LogsDrawer from './logs_drawer.vue';

export default {
  components: {
    GlLoadingIcon,
    LogsTable,
    LogsDrawer,
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
      isDrawerOpen: false,
      selectedLog: null,
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
    onToggleDrawer({ fingerprint }) {
      if (this.selectedLog?.fingerprint === fingerprint) {
        this.closeDrawer();
      } else {
        const log = this.logs.find((s) => s.fingerprint === fingerprint);
        this.selectedLog = log;
      }
    },
    closeDrawer() {
      this.selectedLog = null;
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
      <logs-table :logs="logs" @reload="fetchLogs" @log-selected="onToggleDrawer" />

      <logs-drawer :log="selectedLog" :open="Boolean(selectedLog)" @close="closeDrawer" />
    </div>
  </div>
</template>

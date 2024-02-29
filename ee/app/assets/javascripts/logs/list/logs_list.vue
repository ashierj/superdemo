<script>
import { GlLoadingIcon, GlInfiniteScroll, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { contentTop } from '~/lib/utils/common_utils';
import LogsTable from './logs_table.vue';
import LogsDrawer from './logs_drawer.vue';

const LIST_V_PADDING = 30;
const PAGE_SIZE = 100;

export default {
  components: {
    GlLoadingIcon,
    LogsTable,
    LogsDrawer,
    GlInfiniteScroll,
    GlSprintf,
  },
  i18n: {
    infiniteScrollLegend: s__(`ObservabilityLogs|Showing %{count} logs`),
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
      nextPageToken: null,
    };
  },
  computed: {
    listHeight() {
      return window.innerHeight - contentTop() - LIST_V_PADDING;
    },
  },
  created() {
    this.fetchLogs();
  },
  methods: {
    async fetchLogs() {
      this.loading = true;
      try {
        const { logs, nextPageToken } = await this.observabilityClient.fetchLogs({
          pageToken: this.nextPageToken,
          pageSize: PAGE_SIZE,
        });
        this.logs = [...this.logs, ...logs];
        if (nextPageToken) {
          this.nextPageToken = nextPageToken;
        }
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
    bottomReached() {
      this.fetchLogs();
    },
  },
};
</script>

<template>
  <div>
    <div v-if="loading && logs.length === 0" class="gl-py-5">
      <gl-loading-icon size="lg" />
    </div>

    <template v-else>
      <gl-infinite-scroll
        class="gl-mx-4"
        :max-list-height="listHeight"
        :fetched-items="logs.length"
        @bottomReached="bottomReached"
      >
        <template #items>
          <logs-table :logs="logs" @reload="fetchLogs" @log-selected="onToggleDrawer" />
        </template>

        <template #default>
          <gl-loading-icon v-if="loading" size="md" />
          <span v-else data-testid="logs-infinite-scrolling-legend">
            <gl-sprintf v-if="logs.length" :message="$options.i18n.infiniteScrollLegend">
              <template #count>{{ logs.length }}</template>
            </gl-sprintf>
          </span>
        </template>
      </gl-infinite-scroll>

      <logs-drawer :log="selectedLog" :open="Boolean(selectedLog)" @close="closeDrawer" />
    </template>
  </div>
</template>

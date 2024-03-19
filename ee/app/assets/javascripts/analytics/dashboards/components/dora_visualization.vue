<script>
import { uniq, flatten, uniqBy } from 'lodash';
import { GlSkeletonLoader, GlAlert } from '@gitlab/ui';
import { sprintf } from '~/locale';
import GroupOrProjectProvider from 'ee/analytics/dashboards/components/group_or_project_provider.vue';
import filterLabelsQueryBuilder, { LABEL_PREFIX } from '../graphql/filter_labels_query_builder';
import {
  DASHBOARD_DESCRIPTION_GROUP,
  DASHBOARD_DESCRIPTION_PROJECT,
  DASHBOARD_NAMESPACE_LOAD_ERROR,
  DASHBOARD_LABELS_LOAD_ERROR,
  METRICS_WITHOUT_LABEL_FILTERING,
} from '../constants';
import ComparisonChart from './comparison_chart.vue';
import ComparisonChartLabels from './comparison_chart_labels.vue';

export default {
  name: 'DoraVisualization',
  components: {
    ComparisonChart,
    ComparisonChartLabels,
    GlAlert,
    GlSkeletonLoader,
    GroupOrProjectProvider,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    fullPath: {
      type: String,
      required: true,
    },
    data: {
      type: Object,
      required: true,
    },
  },
  apollo: {
    filterLabelsResults: {
      query() {
        return filterLabelsQueryBuilder(this.filterLabelsQuery, this.isProject);
      },
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      skip() {
        return this.filterLabelsQuery.length === 0 || !this.namespace;
      },
      update(data) {
        const labels = Object.entries(data?.namespace || {})
          .filter(([key]) => key.includes(LABEL_PREFIX))
          .map(([, { nodes }]) => nodes);
        return uniqBy(flatten(labels), ({ id }) => id);
      },
      error() {
        // Fail silently here, an alert will be shown if there are no labels
      },
    },
  },
  data() {
    return {
      namespace: null,
      isProject: false,
      hasNamespaceError: false,
      filterLabelsResults: [],
      chartErrors: [],
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.filterLabelsResults.loading;
    },
    filterLabelsQuery() {
      return this.data?.filter_labels || [];
    },
    hasFilterLabels() {
      return this.filterLabelsResults.length > 0;
    },
    filterLabelNames() {
      return this.filterLabelsResults.map(({ title }) => title);
    },
    excludeMetrics() {
      let metrics = this.data?.exclude_metrics || [];
      if (this.hasFilterLabels) {
        metrics = [...metrics, ...METRICS_WITHOUT_LABEL_FILTERING];
      }
      return uniq(metrics);
    },
    defaultTitle() {
      const name = this.namespace?.name;
      const text = this.isProject ? DASHBOARD_DESCRIPTION_PROJECT : DASHBOARD_DESCRIPTION_GROUP;
      return sprintf(text, { name });
    },
    loadNamespaceError() {
      const { fullPath } = this;
      return sprintf(DASHBOARD_NAMESPACE_LOAD_ERROR, { fullPath });
    },
    loadLabelsError() {
      if (this.filterLabelsQuery.length === 0 || this.filterLabelsResults.length > 0) return '';

      const labels = this.filterLabelsQuery.join(', ');
      return sprintf(DASHBOARD_LABELS_LOAD_ERROR, { labels });
    },
  },
  methods: {
    handleNamespaceError() {
      this.hasNamespaceError = true;
    },
    handleResolveNamespace({ group, project, isProject }) {
      this.namespace = group ?? project;
      this.isProject = isProject;
    },
  },
};
</script>
<template>
  <group-or-project-provider
    #default="{ isNamespaceLoading }"
    :full-path="fullPath"
    @done="handleResolveNamespace"
    @error="handleNamespaceError"
  >
    <div v-if="loading || isNamespaceLoading">
      <gl-skeleton-loader :lines="1" />
    </div>
    <gl-alert
      v-else-if="hasNamespaceError"
      class="gl-mt-5"
      variant="danger"
      :dismissible="false"
      data-testid="load-namespace-error"
    >
      {{ loadNamespaceError }}
    </gl-alert>
    <div v-else>
      <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
        <h5 data-testid="comparison-chart-title">{{ title || defaultTitle }}</h5>
        <comparison-chart-labels
          v-if="hasFilterLabels"
          :labels="filterLabelsResults"
          :web-url="namespace.webUrl"
        />
      </div>

      <gl-alert
        v-if="chartErrors.length"
        :title="s__('Analytics|Failed to fetch data')"
        variant="danger"
        :dismissible="false"
        data-testid="comparison-chart-errors"
      >
        <ul class="gl-m-0">
          <li v-for="error in chartErrors" :key="error">
            {{ error }}
          </li>
        </ul>
      </gl-alert>

      <gl-alert
        v-if="loadLabelsError"
        variant="danger"
        :dismissible="false"
        data-testid="load-labels-error"
      >
        {{ loadLabelsError }}
      </gl-alert>
      <comparison-chart
        v-else
        :request-path="fullPath"
        :is-project="isProject"
        :exclude-metrics="excludeMetrics"
        :filter-labels="filterLabelNames"
        @set-errors="({ errors }) => (chartErrors = errors)"
      />
    </div>
  </group-or-project-provider>
</template>

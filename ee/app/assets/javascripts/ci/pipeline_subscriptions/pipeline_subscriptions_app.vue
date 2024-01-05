<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import GetUpstreamSubscriptions from './graphql/queries/get_upstream_subscriptions.query.graphql';
import GetDownstreamSubscriptions from './graphql/queries/get_downstream_subscriptions.query.graphql';
import PipelineSubscriptionsTable from './components/pipeline_subscriptions_table.vue';

export default {
  name: 'PipelineSubscriptionsApp',
  i18n: {
    upstreamFetchError: s__(
      'PipelineSubscriptions|An error occurred while fetching upstream pipeline subscriptions.',
    ),
    downstreamFetchError: s__(
      'PipelineSubscriptions|An error occurred while fetching downstream pipeline subscriptions.',
    ),
    upstreamTitle: s__('PipelineSubscriptions|Subscriptions'),
    downstreamTitle: s__('PipelineSubscriptions|Subscribed to this project'),
    upstreamEmptyText: s__(
      'PipelineSubscriptions|This project is not subscribed to any project pipelines.',
    ),
    downstreamEmptyText: s__(
      'PipelineSubscriptions|No project subscribes to the pipelines in this project.',
    ),
  },
  components: {
    GlLoadingIcon,
    PipelineSubscriptionsTable,
  },
  inject: {
    projectPath: {
      default: '',
    },
  },
  apollo: {
    upstreamSubscriptions: {
      query: GetUpstreamSubscriptions,
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      update({ project: { ciSubscriptionsProjects } }) {
        return {
          count: ciSubscriptionsProjects.count,
          nodes: ciSubscriptionsProjects.nodes.map((subscription) => {
            return {
              id: subscription.id,
              project: subscription.upstreamProject,
            };
          }),
        };
      },
      error() {
        createAlert({ message: this.$options.i18n.upstreamFetchError });
      },
    },
    downstreamSubscriptions: {
      query: GetDownstreamSubscriptions,
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      update({ project: { ciSubscribedProjects } }) {
        return {
          count: ciSubscribedProjects.count,
          nodes: ciSubscribedProjects.nodes.map((subscription) => {
            return {
              id: subscription.id,
              project: subscription.downstreamProject,
            };
          }),
        };
      },
      error() {
        createAlert({ message: this.$options.i18n.downstreamFetchError });
      },
    },
  },
  data() {
    return {
      upstreamSubscriptions: {
        count: 0,
        nodes: [],
      },
      downstreamSubscriptions: {
        count: 0,
        nodes: [],
      },
    };
  },
  computed: {
    upstreamSubscriptionsLoading() {
      return this.$apollo.queries.upstreamSubscriptions.loading;
    },
    downstreamSubscriptionsLoading() {
      return this.$apollo.queries.downstreamSubscriptions.loading;
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="upstreamSubscriptionsLoading" />
    <pipeline-subscriptions-table
      v-else
      :count="upstreamSubscriptions.count"
      :subscriptions="upstreamSubscriptions.nodes"
      :title="$options.i18n.upstreamTitle"
      :empty-text="$options.i18n.upstreamEmptyText"
      show-actions
    />

    <gl-loading-icon v-if="downstreamSubscriptionsLoading" />
    <pipeline-subscriptions-table
      v-else
      :count="downstreamSubscriptions.count"
      :subscriptions="downstreamSubscriptions.nodes"
      :title="$options.i18n.downstreamTitle"
      :empty-text="$options.i18n.downstreamEmptyText"
    />
  </div>
</template>

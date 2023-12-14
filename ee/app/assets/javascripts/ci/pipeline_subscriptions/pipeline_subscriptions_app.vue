<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import GetUpstreamSubscriptions from './graphql/queries/get_upstream_subscriptions.query.graphql';
import GetDownstreamSubscriptions from './graphql/queries/get_downstream_subscriptions.query.graphql';

export default {
  name: 'PipelineSubscriptionsApp',
  i18n: {
    upstreamFetchError: s__(
      'PipelineSubscriptions|An error occurred while fetching upstream pipeline subscriptions.',
    ),
    downstreamFetchError: s__(
      'PipelineSubscriptions|An error occurred while fetching downstream pipeline subscriptions.',
    ),
  },
  components: {
    GlLoadingIcon,
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
          nodes: ciSubscriptionsProjects.nodes,
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
          nodes: ciSubscribedProjects.nodes,
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
    <ul v-else>
      <li v-for="subscription in upstreamSubscriptions.nodes" :key="subscription.id">
        {{ subscription.upstreamProject.name }}
      </li>
    </ul>

    <gl-loading-icon v-if="downstreamSubscriptionsLoading" />
    <ul v-else>
      <li v-for="subscription in downstreamSubscriptions.nodes" :key="subscription.id">
        {{ subscription.downstreamProject.name }}
      </li>
    </ul>
  </div>
</template>

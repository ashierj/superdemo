<script>
import { GlLink, GlLoadingIcon, GlTableLite, GlEmptyState } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import getAiAgents from '../graphql/queries/get_ai_agents.query.graphql';

const GRAPHQL_PAGE_SIZE = 30;

export default {
  components: {
    GlLink,
    GlLoadingIcon,
    GlEmptyState,
    GlTableLite,
  },
  inject: ['projectPath'],
  props: {
    createAgentPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      agents: {},
      errorMessage: undefined,
    };
  },
  i18n: {
    emptyState: {
      title: s__('AiAgents|Create your own AI Agents'),
      description: s__('AiAgents|Create and manage your AI Agents'),
      createNew: s__('AiAgents|Get started'),
      svgPath: '/assets/illustrations/tanuki_ai_logo.svg',
    },
  },
  fields: [
    {
      key: 'name',
      label: s__('AiAgents|Agent Name'),
    },
  ],
  apollo: {
    agents: {
      query: getAiAgents,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.project?.aiAgents ?? {};
      },
      error(error) {
        this.errorMessage = error.message;
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.agents.loading;
    },
    pageInfo() {
      return this.agents?.pageInfo ?? {};
    },
    queryVariables() {
      return {
        fullPath: this.projectPath,
        first: GRAPHQL_PAGE_SIZE,
      };
    },
    ai_agents() {
      return this.agents?.nodes ?? [];
    },
  },
  methods: {
    fetchPage(pageInfo) {
      const variables = {
        ...this.queryVariables,
        ...pageInfo,
      };

      this.$apollo.queries.agents.fetchMore({
        variables,
        updateQuery: (previousResult, { fetchMoreResult }) => {
          return fetchMoreResult;
        },
      });
    },
  },
};
</script>

<template>
  <span>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-my-5" />
    <gl-table-lite
      v-else-if="ai_agents.length > 0"
      :items="ai_agents"
      sort-by="key"
      sort-direction="asc"
      table-class="text-secondary"
      show-empty
      :fields="$options.fields"
      stacked="false"
      fixed
      data-testId="aiAgentsTable"
    >
      <template #cell(name)="{ item }">
        <gl-link :href="item._links.showPath" class="gl-text-body gl-line-height-24">
          {{ item.name }}
        </gl-link>
      </template>
    </gl-table-lite>

    <gl-empty-state
      v-else
      :title="$options.i18n.emptyState.title"
      :primary-button-text="$options.i18n.emptyState.createNew"
      :primary-button-link="createAgentPath"
      :svg-path="$options.i18n.emptyState.svgPath"
      :svg-height="null"
      :description="$options.i18n.emptyState.description"
      class="gl-py-8"
    />
  </span>
</template>

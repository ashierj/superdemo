<script>
import { GlButton, GlFormGroup, GlFormTextarea, GlIcon } from '@gitlab/ui';
import { v4 as uuidv4 } from 'uuid';

import { fetchPolicies } from '~/lib/graphql';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT, TYPENAME_USER } from '~/graphql_shared/constants';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';

import generateCubeQuery from '../../graphql/mutations/generate_cube_query.mutation.graphql';

export default {
  name: 'AiCubeQueryGenerator',
  components: {
    GlButton,
    GlFormGroup,
    GlIcon,
    GlFormTextarea,
  },
  inject: {
    namespaceId: {
      type: String,
    },
  },
  data() {
    return {
      prompt: null,
      errors: null,
      submitting: false,
      clientSubscriptionId: uuidv4(),
      skipSubscription: true,
    };
  },
  methods: {
    async generateAiQuery() {
      if (this.submitting) return;
      if (!this.prompt) return;

      this.skipSubscription = false;
      this.submitting = true;
      this.errors = null;

      try {
        await this.$apollo.mutate({
          mutation: generateCubeQuery,
          variables: {
            question: this.prompt,
            resourceId: convertToGraphQLId(TYPENAME_PROJECT, this.namespaceId),
            clientSubscriptionId: this.clientSubscriptionId,
            htmlResponse: false,
          },
        });
      } catch (error) {
        // TODO add proper error handling: https://gitlab.com/gitlab-org/gitlab/-/issues/435785
        // eslint-disable-next-line no-console
        console.error('generateCubeQueryMutation: ', error);
        this.errors = [error];
        this.submitting = false;
      }
    },
  },
  apollo: {
    $subscribe: {
      generateCubeQuery: {
        query: aiResponseSubscription,
        // Apollo wants to write the subscription result to the cache, but we have none because we also
        // don't have a query. We only use this subscription as a notification.
        fetchPolicy: fetchPolicies.NO_CACHE,
        skip() {
          return this.skipSubscription;
        },
        variables() {
          return {
            resourceId: convertToGraphQLId(TYPENAME_PROJECT, this.namespaceId),
            userId: convertToGraphQLId(TYPENAME_USER, window.gon.current_user_id),
            clientSubscriptionId: this.clientSubscriptionId,
          };
        },
        error(error) {
          // TODO add proper error handling: https://gitlab.com/gitlab-org/gitlab/-/issues/435785
          // eslint-disable-next-line no-console
          console.error('aiResponseSubscription: ', error);
          this.errors = [error];
        },
        result({ data }) {
          const { errors = [], content } = data.aiCompletionResponse || {};

          if (errors.length) {
            // TODO add proper error handling: https://gitlab.com/gitlab-org/gitlab/-/issues/435785
            // eslint-disable-next-line no-console
            console.error('aiResponseSubscription: ', { errors, content });
            this.errors = errors;
            this.submitting = false;
            return;
          }

          if (!content) {
            return;
          }

          this.submitting = false;

          try {
            const query = JSON.parse(content);
            this.$emit('query-generated', query);
          } catch (error) {
            // TODO add proper error handling: https://gitlab.com/gitlab-org/gitlab/-/issues/435785
            // eslint-disable-next-line no-console
            console.error('parseGeneratedResponse: ', { error, content });
          }
        },
      },
    },
  },
};
</script>

<template>
  <gl-form-group>
    <template #label>
      {{ s__('Analytics|Create with GitLab Duo') }}
      <gl-icon name="tanuki-ai" class="gl-text-purple-600 gl-ml-1" />
    </template>
    <gl-form-textarea
      v-model="prompt"
      :placeholder="s__('Analytics|Count of page views grouped weekly')"
      :submit-on-enter="true"
      data-testid="generate-cube-query-prompt-input"
      @submit="generateAiQuery"
    />
    <gl-button
      :loading="submitting"
      class="gl-mt-3"
      data-testid="generate-cube-query-submit-button"
      @click="generateAiQuery"
      >{{ s__('Analytics|Generate visualization') }}</gl-button
    >
  </gl-form-group>
</template>

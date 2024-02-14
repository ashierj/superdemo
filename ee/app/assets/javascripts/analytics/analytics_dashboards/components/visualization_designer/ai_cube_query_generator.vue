<script>
import { GlButton, GlExperimentBadge, GlFormGroup, GlFormTextarea, GlIcon } from '@gitlab/ui';
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
    GlExperimentBadge,
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
  computed: {
    submitButtonIcon() {
      return this.submitting ? undefined : 'tanuki-ai';
    },
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
      <gl-icon name="tanuki-ai" class="gl-mr-1" />
      {{ s__('Analytics|Create with GitLab Duo (optional)') }}
      <gl-experiment-badge />
    </template>
    <p class="gl-mb-3">
      {{
        s__(
          'Analytics|GitLab Duo may be used to help generate your visualization. You can prompt Duo with your desired data, as well as any dimensions or additional groupings of that data. You may also edit the result as needed.',
        )
      }}
    </p>
    <gl-form-textarea
      v-model="prompt"
      :placeholder="s__('Analytics|Example: Number of users over time, grouped weekly')"
      :submit-on-enter="true"
      class="gl-w-full gl-md-max-w-70p gl-lg-w-30p gl-min-w-20"
      data-testid="generate-cube-query-prompt-input"
      @submit="generateAiQuery"
    />
    <gl-button
      :loading="submitting"
      category="secondary"
      variant="confirm"
      :icon="submitButtonIcon"
      class="gl-mt-3"
      data-testid="generate-cube-query-submit-button"
      @click="generateAiQuery"
      >{{ s__('Analytics|Generate with Duo') }}</gl-button
    >
  </gl-form-group>
</template>

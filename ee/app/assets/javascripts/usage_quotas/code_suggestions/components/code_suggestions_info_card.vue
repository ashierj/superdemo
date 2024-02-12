<script>
import { GlCard, GlLink, GlSprintf, GlButton, GlSkeletonLoader } from '@gitlab/ui';
import { s__ } from '~/locale';
import UsageStatistics from 'ee/usage_quotas/components/usage_statistics.vue';
import { codeSuggestionsLearnMoreLink } from 'ee/usage_quotas/code_suggestions/constants';
import { addSeatsText } from 'ee/usage_quotas/seats/constants';
import Tracking from '~/tracking';
import { getSubscriptionPermissionsData } from 'ee/fulfillment/shared_queries/subscription_actions_reason.customer.query.graphql';

export default {
  name: 'CodeSuggestionsUsageInfoCard',
  helpLinks: {
    codeSuggestionsLearnMoreLink,
  },
  i18n: {
    description: s__(
      `CodeSuggestions|%{linkStart}Code Suggestions%{linkEnd} uses generative AI to suggest code while you're developing.`,
    ),
    title: s__('CodeSuggestions|GitLab Duo Pro add-on'),
    addSeatsText,
  },
  components: {
    GlButton,
    GlCard,
    GlLink,
    GlSprintf,
    UsageStatistics,
    GlSkeletonLoader,
  },
  mixins: [Tracking.mixin()],
  inject: ['addDuoProHref', 'isSaaS'],
  props: {
    groupId: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    parsedGroupId() {
      return parseInt(this.groupId, 10);
    },
    shouldShowAddSeatsButton() {
      return (
        !this.isLoading &&
        this.addDuoProHref &&
        this.groupId &&
        this.subscriptionPermissions?.canAddDuoProSeats
      );
    },
    isLoading() {
      return this.$apollo.queries.subscriptionPermissions.loading;
    },
    trackingPreffix() {
      return this.isSaaS ? 'saas' : 'sm';
    },
  },
  apollo: {
    subscriptionPermissions: {
      query: getSubscriptionPermissionsData,
      client: 'customersDotClient',
      variables() {
        return {
          namespaceId: this.parsedGroupId,
        };
      },
      skip() {
        return !this.addDuoProHref || !this.groupId;
      },
      update: (data) => ({
        canAddDuoProSeats: data.subscription.canAddDuoProSeats,
      }),
    },
  },
  methods: {
    handleAddDuoProClick() {
      this.track('click_button', {
        label: `add_duo_pro_${this.trackingPreffix}`,
        property: 'usage_quotas_page',
      });
    },
  },
};
</script>
<template>
  <gl-card class="gl-p-3">
    <gl-skeleton-loader v-if="isLoading" :height="64">
      <rect width="140" height="30" x="5" y="0" rx="4" />
      <rect width="240" height="10" x="5" y="40" rx="4" />
      <rect width="340" height="10" x="5" y="54" rx="4" />
    </gl-skeleton-loader>
    <usage-statistics v-else>
      <template #description>
        <p class="gl-font-weight-bold gl-mb-0" data-testid="title">{{ $options.i18n.title }}</p>
      </template>
      <template #additional-info>
        <p class="gl-mt-5" data-testid="description">
          <gl-sprintf :message="$options.i18n.description">
            <template #link="{ content }">
              <gl-link :href="$options.helpLinks.codeSuggestionsLearnMoreLink" target="_blank">{{
                content
              }}</gl-link>
            </template>
          </gl-sprintf>
        </p>
      </template>
      <template #actions>
        <gl-button
          v-if="shouldShowAddSeatsButton"
          category="primary"
          variant="confirm"
          target="_blank"
          :href="addDuoProHref"
          @click="handleAddDuoProClick"
        >
          {{ $options.i18n.addSeatsText }}
        </gl-button>
      </template>
    </usage-statistics>
  </gl-card>
</template>

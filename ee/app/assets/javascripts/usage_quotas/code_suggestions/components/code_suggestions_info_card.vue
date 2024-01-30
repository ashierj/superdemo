<script>
import { GlButton, GlCard, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import UsageStatistics from 'ee/usage_quotas/components/usage_statistics.vue';
import { codeSuggestionsLearnMoreLink } from 'ee/usage_quotas/code_suggestions/constants';
import { addSeatsText } from 'ee/usage_quotas/seats/constants';
import Tracking from '~/tracking';

export default {
  name: 'CodeSuggestionsUsageInfoCard',
  helpLinks: {
    codeSuggestionsLearnMoreLink,
  },
  i18n: {
    description: s__(
      `CodeSuggestions|%{linkStart}Code Suggestions%{linkEnd} uses generative AI to suggest code while you're developing.`,
    ),
    title: s__('CodeSuggestions|Duo Pro add-on'),
    addSeatsText,
  },
  components: {
    GlButton,
    GlCard,
    GlLink,
    GlSprintf,
    UsageStatistics,
  },
  mixins: [Tracking.mixin()],
  inject: ['addDuoProHref', 'isSaaS'],
  computed: {
    trackingPreffix() {
      return this.isSaaS ? 'saas' : 'sm';
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
    <usage-statistics>
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
          v-if="addDuoProHref"
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

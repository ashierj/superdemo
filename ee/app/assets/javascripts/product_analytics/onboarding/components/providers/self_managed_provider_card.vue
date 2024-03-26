<script>
import { GlButton } from '@gitlab/ui';

import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import { s__ } from '~/locale';

import ProviderSettingsPreview from './provider_settings_preview.vue';
import { getRedirectConfirmationMessage } from './utils';

export default {
  name: 'SelfManagedProviderCard',
  components: { GlButton, ProviderSettingsPreview },
  inject: {
    projectLevelAnalyticsProviderSettings: {},
  },
  props: {
    projectAnalyticsSettingsPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    hasCompleteProjectLevelProviderConfig() {
      return Object.values(this.projectLevelAnalyticsProviderSettings).every(Boolean);
    },
  },
  methods: {
    async onSelected() {
      if (!this.hasCompleteProjectLevelProviderConfig) {
        await this.promptToSetSettings();
        return;
      }

      this.$emit('confirm');
    },
    async promptToSetSettings() {
      const confirmed = await confirmAction('', {
        title: s__('ProductAnalytics|Connect your own provider'),
        primaryBtnText: s__('ProductAnalytics|Go to analytics settings'),
        modalHtmlMessage: getRedirectConfirmationMessage(
          s__(
            `ProductAnalytics|To connect your own provider, you'll be redirected to the %{analyticsSettingsLink} page, which shows your provider's configuration settings and setup instructions.`,
          ),
          this.projectAnalyticsSettingsPath,
        ),
      });

      if (confirmed) {
        this.$emit('open-settings');
      }
    },
  },
};
</script>
<template>
  <div
    class="gl-display-flex gl-gap-6 gl-border-gray-100 gl-border-solid border-radius-default gl-w-full gl-p-6"
  >
    <div class="gl-display-flex gl-flex-direction-column">
      <h3 class="gl-mt-0 text-4">
        {{ s__('ProductAnalytics|Self-managed provider') }}
      </h3>
      <p class="gl-mb-6">
        {{
          s__(
            'ProductAnalytics|Manage your own analytics provider to process, store, and query analytics data.',
          )
        }}
      </p>
      <div v-if="hasCompleteProjectLevelProviderConfig">
        <p>{{ s__('ProductAnalytics|Your instance will be created on this provider:') }}</p>
        <provider-settings-preview
          :configurator-connection-string="
            projectLevelAnalyticsProviderSettings.productAnalyticsConfiguratorConnectionString
          "
          :collector-host="projectLevelAnalyticsProviderSettings.productAnalyticsDataCollectorHost"
          :cube-api-base-url="projectLevelAnalyticsProviderSettings.cubeApiBaseUrl"
          :cube-api-key="projectLevelAnalyticsProviderSettings.cubeApiKey"
        />
      </div>
      <template v-else>
        <h4 class="gl-font-lg">{{ s__('ProductAnalytics|For this option, you need:') }}</h4>
        <ul class="gl-mb-6">
          <li>
            {{ s__('ProductAnalytics|A deployed instance of the analytics-stack project.') }}
          </li>
          <li>{{ s__('ProductAnalytics|Valid project settings.') }}</li>
        </ul>
      </template>

      <gl-button
        category="primary"
        variant="confirm"
        class="gl-mt-auto gl-align-self-start"
        data-testid="connect-your-own-provider-btn"
        @click="onSelected"
        >{{ s__('ProductAnalytics|Connect your own provider') }}</gl-button
      >
    </div>
  </div>
</template>

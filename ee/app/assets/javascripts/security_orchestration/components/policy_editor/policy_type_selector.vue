<script>
import shieldCheckIllustrationUrl from '@gitlab/svgs/dist/illustrations/secure-sm.svg?url';
import magnifyingGlassIllustrationUrl from '@gitlab/svgs/dist/illustrations/search-sm.svg?url';
import { GlButton, GlCard, GlIcon, GlPopover, GlSprintf } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__, __ } from '~/locale';
import { POLICY_TYPE_COMPONENT_OPTIONS } from '../constants';

const i18n = {
  cancel: __('Cancel'),
  examples: __('Examples'),
  selectPolicy: s__('SecurityOrchestration|Select policy'),
  scanResultPolicyTitle: s__('SecurityOrchestration|Merge request approval policy'),
  scanResultPolicyTitlePopoverTitle: s__('SecurityOrchestration|Updated policy name'),
  scanResultPolicyTitlePopoverDesc: s__(
    'SecurityOrchestration|The Scan result policy is now called the Merge request approval policy to better align with its purpose. For more details, see the release notes.',
  ),
  scanResultPolicySubTitle: s__('SecurityOrchestraation|(Formerly Scan result policy)'),
  scanResultPolicyDesc: s__(
    'SecurityOrchestration|Use a merge request approval policy to create rules that check for security vulnerabilities and license compliance before merging a merge request.',
  ),
  scanResultPolicyExample: s__(
    'SecurityOrchestration|If any scanner finds a newly detected critical vulnerability in an open merge request targeting the main branch, then require two approvals from any two members of the application security team are required.',
  ),
  scanExecutionPolicyTitle: s__('SecurityOrchestration|Scan execution policy'),
  scanExecutionPolicyDesc: s__(
    'SecurityOrchestration|Use a scan execution policy to create rules which enforce security scans for particular branches at a certain time. Supported types are SAST, SAST IaC, DAST, Secret detection, Container scanning, and Dependency scanning.',
  ),
  scanExecutionPolicyExample: s__(
    'SecurityOrchestration|Run a DAST scan with Scan Profile A and Site Profile A when a pipeline run against the main branch.',
  ),
  maximumReachedWarning: s__(
    'SecurityOrchestration|You already have the maximum %{maximumAllowed} %{policyType} policies.',
  ),
};

export default {
  components: {
    GlButton,
    GlCard,
    GlIcon,
    GlPopover,
    GlSprintf,
  },
  directives: {
    SafeHtml,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: [
    'maxActiveScanExecutionPoliciesReached',
    'maxActiveScanResultPoliciesReached',
    'maxScanExecutionPoliciesAllowed',
    'maxScanResultPoliciesAllowed',
    'policiesPath',
  ],
  computed: {
    policies() {
      return [
        {
          text: POLICY_TYPE_COMPONENT_OPTIONS.scanResult.text.toLowerCase(),
          urlParameter: POLICY_TYPE_COMPONENT_OPTIONS.approval.urlParameter,
          title: i18n.scanResultPolicyTitle,
          titlePopover: i18n.scanResultPolicyTitlePopoverTitle,
          titlePopoverDesc: i18n.scanResultPolicyTitlePopoverDesc,
          description: i18n.scanResultPolicyDesc,
          example: i18n.scanResultPolicyExample,
          imageSrc: shieldCheckIllustrationUrl,
          hasMax: this.maxActiveScanResultPoliciesReached,
          maxPoliciesAllowed: this.maxScanResultPoliciesAllowed,
          subtitle: i18n.scanResultPolicySubTitle,
        },
        {
          text: POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.text.toLowerCase(),
          urlParameter: POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.urlParameter,
          title: i18n.scanExecutionPolicyTitle,
          description: i18n.scanExecutionPolicyDesc,
          example: i18n.scanExecutionPolicyExample,
          imageSrc: magnifyingGlassIllustrationUrl,
          hasMax: this.maxActiveScanExecutionPoliciesReached,
          maxPoliciesAllowed: this.maxScanExecutionPoliciesAllowed,
        },
      ];
    },
  },
  i18n,
  safeHtmlConfig: { ADD_TAGS: ['use'] },
};
</script>
<template>
  <div class="gl-mb-4">
    <div
      class="gl-display-grid gl-md-grid-template-columns-2 gl-gap-6 gl-mb-4"
      data-testid="policy-selection-wizard"
    >
      <gl-card
        v-for="option in policies"
        :key="option.title"
        body-class="gl-p-6 gl-display-flex gl-flex-grow-1"
      >
        <div class="gl-mr-6 gl-text-white">
          <img :alt="option.title" aria-hidden="true" :src="option.imageSrc" />
        </div>
        <div class="gl-display-flex gl-flex-direction-column">
          <div>
            <h4 class="gl-display-inline-block gl-my-0">{{ option.title }}</h4>
            <gl-icon
              v-if="option.titlePopover"
              id="change-icon"
              name="status-active"
              :size="12"
              class="gl-display-inline-block gl-text-blue-500"
            />
            <gl-popover
              v-if="option.titlePopover"
              triggers="hover focus"
              :title="option.titlePopover"
              :show-close-button="false"
              placement="top"
              target="change-icon"
              :content="option.titlePopoverDesc"
              :show="false"
            />
          </div>
          <p v-if="option.subtitle" class="gl-text-gray-400">{{ option.subtitle }}</p>
          <p>{{ option.description }}</p>
          <h5>{{ $options.i18n.examples }}</h5>
          <p class="gl-flex-grow-1">{{ option.example }}</p>
          <div>
            <gl-button
              v-if="!option.hasMax"
              variant="confirm"
              :data-testid="`select-policy-${option.urlParameter}`"
              @click="$emit('select', option.urlParameter)"
            >
              {{ $options.i18n.selectPolicy }}
            </gl-button>
            <span
              v-else
              class="gl-text-orange-500"
              :data-testid="`max-allowed-text-${option.urlParameter}`"
            >
              <gl-icon name="warning" />
              <gl-sprintf :message="$options.i18n.maximumReachedWarning">
                <template #maximumAllowed>{{ option.maxPoliciesAllowed }}</template>
                <template #policyType>{{ option.text }}</template>
              </gl-sprintf>
            </span>
          </div>
        </div>
      </gl-card>
    </div>
    <gl-button :href="policiesPath" data-testid="back-button">{{ $options.i18n.cancel }}</gl-button>
  </div>
</template>

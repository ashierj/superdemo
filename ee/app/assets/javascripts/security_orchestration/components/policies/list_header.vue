<script>
import { GlAlert, GlButton, GlIcon, GlSprintf } from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { NEW_POLICY_BUTTON_TEXT } from '../constants';
import ExperimentFeaturesBanner from './experiment_features_banner.vue';
import ProjectModal from './project_modal.vue';

export default {
  BANNER_STORAGE_KEY: 'security_policies_scan_result_name_change',
  components: {
    ExperimentFeaturesBanner,
    GlAlert,
    GlButton,
    GlIcon,
    GlSprintf,
    LocalStorageSync,
    ProjectModal,
  },
  mixins: [glFeatureFlagMixin()],
  inject: [
    'assignedPolicyProject',
    'disableSecurityPolicyProject',
    'disableScanPolicyUpdate',
    'documentationPath',
    'newPolicyPath',
  ],
  i18n: {
    title: s__('SecurityOrchestration|Policies'),
    subtitle: s__(
      'SecurityOrchestration|Enforce %{linkStart}security policies%{linkEnd} for this project.',
    ),
    newPolicyButtonText: NEW_POLICY_BUTTON_TEXT,
    editPolicyProjectButtonText: s__('SecurityOrchestration|Edit policy project'),
    viewPolicyProjectButtonText: s__('SecurityOrchestration|View policy project'),
    migrationTitle: s__('SecurityOrchestration|Updated policy name'),
    migrationDescription: s__(
      'SecurityOrchestration|The %{oldNameStart}Scan result policy%{oldNameEnd} is now called the %{newNameStart}Merge request approval policy%{newNameEnd} to better align with its purpose. For more details, see the release notes.',
    ),
  },
  data() {
    return {
      projectIsBeingLinked: false,
      showAlert: false,
      migrationAlertDismissed: false,
      alertVariant: '',
      alertText: '',
      modalVisible: false,
    };
  },
  computed: {
    feedbackBannerEnabled() {
      return (
        this.glFeatures.securityPoliciesPolicyScope || this.glFeatures.compliancePipelineInPolicies
      );
    },
    hasAssignedPolicyProject() {
      return Boolean(this.assignedPolicyProject?.id);
    },
    securityPolicyProjectPath() {
      return joinPaths('/', this.assignedPolicyProject?.full_path);
    },
  },
  methods: {
    updateAlertText({ text, variant, hasPolicyProject }) {
      this.projectIsBeingLinked = false;

      if (text) {
        this.showAlert = true;
        this.alertVariant = variant;
        this.alertText = text;
      }
      this.$emit('update-policy-list', { hasPolicyProject, shouldUpdatePolicyList: true });
    },
    isUpdatingProject() {
      this.projectIsBeingLinked = true;
      this.showAlert = false;
      this.alertVariant = '';
      this.alertText = '';
    },
    dismissAlert() {
      this.showAlert = false;
    },
    dismissMigrationAlert() {
      this.migrationAlertDismissed = true;
    },
    showNewPolicyModal() {
      this.modalVisible = true;
    },
  },
};
</script>
<template>
  <div>
    <gl-alert
      v-if="showAlert"
      class="gl-mt-3"
      :dismissible="true"
      :variant="alertVariant"
      data-testid="error-alert"
      @dismiss="dismissAlert"
    >
      {{ alertText }}
    </gl-alert>
    <header class="gl-my-6 gl-display-flex gl-flex-direction-column">
      <div class="gl-display-flex gl-align-items-flex-start">
        <div class="gl-flex-grow-1 gl-my-0">
          <h2 class="gl-mt-0">
            {{ $options.i18n.title }}
          </h2>
          <p data-testid="policies-subheader">
            <gl-sprintf :message="$options.i18n.subtitle">
              <template #link="{ content }">
                <gl-button
                  class="gl-pb-1!"
                  variant="link"
                  :href="documentationPath"
                  target="_blank"
                >
                  {{ content }}
                </gl-button>
              </template>
            </gl-sprintf>
          </p>
        </div>
        <gl-button
          v-if="!disableSecurityPolicyProject"
          data-testid="edit-project-policy-button"
          class="gl-mr-4"
          :loading="projectIsBeingLinked"
          @click="showNewPolicyModal"
        >
          {{ $options.i18n.editPolicyProjectButtonText }}
        </gl-button>
        <gl-button
          v-else-if="hasAssignedPolicyProject"
          data-testid="view-project-policy-button"
          class="gl-mr-3"
          target="_blank"
          :href="securityPolicyProjectPath"
        >
          <gl-icon name="external-link" />
          {{ $options.i18n.viewPolicyProjectButtonText }}
        </gl-button>
        <gl-button
          v-if="!disableScanPolicyUpdate"
          data-testid="new-policy-button"
          variant="confirm"
          :href="newPolicyPath"
        >
          {{ $options.i18n.newPolicyButtonText }}
        </gl-button>
      </div>

      <experiment-features-banner v-if="feedbackBannerEnabled" />

      <project-modal
        :visible="modalVisible"
        @close="modalVisible = false"
        @project-updated="updateAlertText"
        @updating-project="isUpdatingProject"
      />
    </header>
    <local-storage-sync
      v-model="migrationAlertDismissed"
      :storage-key="$options.BANNER_STORAGE_KEY"
    >
      <gl-alert
        v-if="!migrationAlertDismissed"
        class="gl-mt-3 gl-mb-6"
        :dismissible="true"
        :title="$options.i18n.migrationTitle"
        data-testid="migration-alert"
        @dismiss="dismissMigrationAlert()"
      >
        <gl-sprintf :message="$options.i18n.migrationDescription">
          <template #oldName="{ content }">
            <b>{{ content }}</b>
          </template>
          <template #newName="{ content }">
            <b>{{ content }}</b>
          </template>
        </gl-sprintf>
      </gl-alert>
    </local-storage-sync>
  </div>
</template>

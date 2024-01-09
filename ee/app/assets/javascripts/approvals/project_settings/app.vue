<script>
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ApprovalRulesApp from 'ee/approvals/components/approval_rules_app.vue';
import ScanResultPolicies from 'ee/approvals/components/security_orchestration/scan_result_policies.vue';
import ProjectApprovalSettings from './project_approval_settings.vue';
import ProjectRules from './project_rules.vue';

export default {
  components: {
    ApprovalRulesApp,
    ProjectApprovalSettings,
    ProjectRules,
    ScanResultPolicies,
  },
  mixins: [glFeatureFlagMixin()],
};
</script>

<template>
  <div>
    <approval-rules-app :is-mr-edit="false">
      <template #rules>
        <project-rules />
      </template>
    </approval-rules-app>
    <scan-result-policies v-if="glFeatures.securityOrchestrationPolicies" class="gl-mt-5" />
    <project-approval-settings class="gl-mt-5" />
  </div>
</template>

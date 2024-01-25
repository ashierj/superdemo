<script>
import IssuesDashboardApp from '~/issues/dashboard/components/issues_dashboard_app.vue';
import { TYPE_TOKEN_KEY_RESULT_OPTION, TYPE_TOKEN_OBJECTIVE_OPTION } from '~/issues/list/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    IssuesDashboardApp,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['hasOkrsFeature'],
  computed: {
    isOkrsEnabled() {
      return this.hasOkrsFeature && this.glFeatures.okrsMvc;
    },
    typeTokenOptions() {
      const typeTokens = [];
      if (this.isOkrsEnabled) {
        typeTokens.push(TYPE_TOKEN_OBJECTIVE_OPTION, TYPE_TOKEN_KEY_RESULT_OPTION);
      }
      return typeTokens;
    },
  },
};
</script>

<template>
  <issues-dashboard-app :ee-type-token-options="typeTokenOptions" />
</template>

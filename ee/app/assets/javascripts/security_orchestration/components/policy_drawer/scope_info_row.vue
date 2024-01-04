<script>
import {
  EXCLUDING,
  INCLUDING,
} from 'ee/security_orchestration/components/policy_editor/scope/constants';
import {
  DEFAULT_SCOPE_LABEL,
  SCOPE_TITLE,
} from 'ee/security_orchestration/components/policy_drawer/constants';
import ComplianceFrameworksToggleList from './compliance_frameworks_toggle_list.vue';
import ProjectsToggleList from './projects_toggle_list.vue';
import InfoRow from './info_row.vue';

export default {
  name: 'ScopeInfoRow',
  components: {
    ComplianceFrameworksToggleList,
    InfoRow,
    ProjectsToggleList,
  },
  i18n: {
    defaultScope: DEFAULT_SCOPE_LABEL,
    scopeTitle: SCOPE_TITLE,
  },
  props: {
    policyScope: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    policyScopeHasComplianceFrameworks() {
      const { compliance_frameworks: complianceFrameworks = [] } = this.policyScope || {};
      return Boolean(complianceFrameworks) && complianceFrameworks?.length > 0;
    },
    policyScopeHasIncludingProjects() {
      const { projects: { including = [] } = {} } = this.policyScope || {};
      return Boolean(including) && including?.length > 0;
    },
    policyScopeHasExcludingProjects() {
      return Boolean(this.policyScope?.projects?.excluding);
    },
    policyHasProjects() {
      return this.policyScopeHasIncludingProjects || this.policyScopeHasExcludingProjects;
    },
    policyScopeProjectsKey() {
      return this.policyScopeHasIncludingProjects ? INCLUDING : EXCLUDING;
    },
    policyScopeProjectsIds() {
      return this.policyScope?.projects?.[this.policyScopeProjectsKey]?.map(({ id }) => id) || [];
    },
    policyScopeComplianceFrameworkIds() {
      return this.policyScope?.compliance_frameworks?.map(({ id }) => id) || [];
    },
  },
};
</script>

<template>
  <info-row :label="$options.i18n.scopeTitle" data-testid="policy-scope">
    <div class="gl-display-inline-flex gl-gap-3 gl-flex-wrap">
      <template v-if="policyScopeHasComplianceFrameworks">
        <compliance-frameworks-toggle-list
          :compliance-framework-ids="policyScopeComplianceFrameworkIds"
        />
      </template>
      <template v-else-if="policyHasProjects">
        <projects-toggle-list
          :including="policyScopeHasIncludingProjects"
          :project-ids="policyScopeProjectsIds"
        />
      </template>
      <div v-else class="gl-text-gray-500" data-testid="default-scope-text">
        {{ $options.i18n.defaultScope }}
      </div>
    </div>
  </info-row>
</template>

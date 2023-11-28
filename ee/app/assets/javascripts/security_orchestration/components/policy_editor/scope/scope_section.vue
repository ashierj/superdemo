<script>
import { GlAlert, GlCollapsibleListbox, GlSprintf } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import PolicyPopover from 'ee/security_orchestration/components/policy_popover.vue';
import GroupProjectsDropdown from '../../group_projects_dropdown.vue';
import ComplianceFrameworkDropdown from './compliance_framework_dropdown.vue';
import {
  PROJECTS_WITH_FRAMEWORK,
  PROJECT_SCOPE_TYPE_LISTBOX_ITEMS,
  PROJECT_SCOPE_TYPE_TEXTS,
  EXCEPTION_TYPE_LISTBOX_ITEMS,
  EXCEPTION_TYPE_TEXTS,
  WITHOUT_EXCEPTIONS,
  SPECIFIC_PROJECTS,
  EXCEPT_PROJECTS,
  ALL_PROJECTS_IN_GROUP,
  INCLUDING,
  EXCLUDING,
  COMPLIANCE_FRAMEWORKS_KEY,
  PROJECTS_KEY,
} from './constants';

export default {
  COMPLIANCE_FRAMEWORK_PATH: helpPagePath('user/group/compliance_frameworks.md'),
  PROJECT_SCOPE_TYPE_LISTBOX_ITEMS,
  EXCEPTION_TYPE_LISTBOX_ITEMS,
  i18n: {
    policyScopeFrameworkCopy: s__(
      `SecurityOrchestration|Apply this policy to all projects %{projectScopeType} named %{frameworkSelector}`,
    ),
    policyScopeProjectCopy: s__(
      `SecurityOrchestration|Apply this policy to all projects %{projectScopeType} %{exceptionType} %{projectSelector}`,
    ),
    groupProjectErrorDescription: s__('SecurityOrchestration|Failed to load group projects'),
    complianceFrameworkErrorDescription: s__(
      'SecurityOrchestration|Failed to load compliance frameworks',
    ),
    complianceFrameworkPopoverTitle: __('Information'),
    complianceFrameworkPopoverContent: s__(
      'SecurityOrchestration|A compliance framework is a label to identify that your project has certain compliance requirements. %{linkStart}Learn more%{linkEnd}.',
    ),
  },
  name: 'ScopeSection',
  components: {
    GlAlert,
    GlCollapsibleListbox,
    ComplianceFrameworkDropdown,
    GlSprintf,
    GroupProjectsDropdown,
    PolicyPopover,
  },
  inject: ['namespacePath', 'rootNamespacePath'],
  props: {
    policyScope: {
      type: Object,
      required: true,
      default: () => ({}),
    },
  },
  data() {
    let selectedProjectScopeType = PROJECTS_WITH_FRAMEWORK;
    let selectedExceptionType = WITHOUT_EXCEPTIONS;
    let projectsPayloadKey = EXCLUDING;

    const { projects = [] } = this.policyScope || {};

    if (projects?.excluding) {
      selectedProjectScopeType = ALL_PROJECTS_IN_GROUP;
      selectedExceptionType = EXCEPT_PROJECTS;
    }

    if (projects?.including) {
      selectedProjectScopeType = SPECIFIC_PROJECTS;
      projectsPayloadKey = INCLUDING;
    }

    return {
      selectedProjectScopeType,
      selectedExceptionType,
      projectsPayloadKey,
      showAlert: false,
      errorDescription: '',
    };
  },
  computed: {
    projectIds() {
      /**
       * Protection from manual yam input as objects
       * @type {*|*[]}
       */
      const projects = Array.isArray(this.policyScope?.projects?.[this.projectsPayloadKey])
        ? this.policyScope?.projects?.[this.projectsPayloadKey]
        : [];

      return projects?.map(({ id }) => convertToGraphQLId(TYPENAME_PROJECT, id)) || [];
    },
    complianceFrameworksIds() {
      /**
       * Protection from manual yam input as objects
       * @type {*|*[]}
       */
      const frameworks = Array.isArray(this.policyScope?.compliance_frameworks)
        ? this.policyScope?.compliance_frameworks
        : [];
      return frameworks?.map(({ id }) => id) || [];
    },
    selectedProjectScopeText() {
      return PROJECT_SCOPE_TYPE_TEXTS[this.selectedProjectScopeType];
    },
    selectedExceptionTypeText() {
      return EXCEPTION_TYPE_TEXTS[this.selectedExceptionType];
    },
    showExceptionTypeDropdown() {
      return this.selectedProjectScopeType === ALL_PROJECTS_IN_GROUP;
    },
    showGroupProjectsDropdown() {
      return (
        (this.showExceptionTypeDropdown && this.selectedExceptionType === EXCEPT_PROJECTS) ||
        this.selectedProjectScopeType === SPECIFIC_PROJECTS
      );
    },
    payloadKey() {
      return this.selectedProjectScopeType === PROJECTS_WITH_FRAMEWORK
        ? COMPLIANCE_FRAMEWORKS_KEY
        : PROJECTS_KEY;
    },
    policyScopeCopy() {
      return this.selectedProjectScopeType === PROJECTS_WITH_FRAMEWORK
        ? this.$options.i18n.policyScopeFrameworkCopy
        : this.$options.i18n.policyScopeProjectCopy;
    },
  },
  methods: {
    resetPolicyScope() {
      const internalPayload =
        this.payloadKey === COMPLIANCE_FRAMEWORKS_KEY ? [] : { [this.projectsPayloadKey]: [] };
      const payload = {
        [this.payloadKey]: internalPayload,
      };

      this.$emit('changed', payload);
    },
    selectProjectScopeType(scopeType) {
      this.selectedProjectScopeType = scopeType;
      this.projectsPayloadKey =
        this.selectedProjectScopeType === ALL_PROJECTS_IN_GROUP ? EXCLUDING : INCLUDING;
      this.resetPolicyScope();
    },
    selectExceptionType(type) {
      this.selectedExceptionType = type;
      this.resetPolicyScope();
    },
    setSelectedProjectIds(projects) {
      const projectsIds = projects.map(({ id }) => ({ id: getIdFromGraphQLId(id) }));
      const payload = { projects: { [this.projectsPayloadKey]: projectsIds } };

      this.triggerChanged(payload);
    },
    setSelectedFrameworkIds(ids) {
      const payload = ids.map((id) => ({ id }));
      this.triggerChanged({ compliance_frameworks: payload });
    },
    triggerChanged(value) {
      this.$emit('changed', { ...this.policyScope, ...value });
    },
    setShowAlert(errorDescription) {
      this.showAlert = true;
      this.errorDescription = errorDescription;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="showAlert" class="gl-mb-5" variant="danger" :dismissible="false">
      {{ errorDescription }}
    </gl-alert>

    <div class="gl-display-flex gl-gap-3 gl-align-items-center gl-flex-wrap gl-mt-2 gl-mb-6">
      <gl-sprintf :message="policyScopeCopy">
        <template #projectScopeType>
          <gl-collapsible-listbox
            data-testid="project-scope-type"
            :items="$options.PROJECT_SCOPE_TYPE_LISTBOX_ITEMS"
            :selected="selectedProjectScopeType"
            :toggle-text="selectedProjectScopeText"
            @select="selectProjectScopeType"
          />
        </template>

        <template #frameworkSelector>
          <div class="gl-display-inline-flex gl-align-items-center gl-flex-wrap gl-gap-3">
            <compliance-framework-dropdown
              :selected-framework-ids="complianceFrameworksIds"
              :full-path="rootNamespacePath"
              @framework-query-error="
                setShowAlert($options.i18n.complianceFrameworkErrorDescription)
              "
              @select="setSelectedFrameworkIds"
            />

            <policy-popover
              :content="$options.i18n.complianceFrameworkPopoverContent"
              :href="$options.COMPLIANCE_FRAMEWORK_PATH"
              :title="$options.i18n.complianceFrameworkPopoverTitle"
              target="compliance-framework-icon"
            />
          </div>
        </template>

        <template #exceptionType>
          <gl-collapsible-listbox
            v-if="showExceptionTypeDropdown"
            data-testid="exception-type"
            :items="$options.EXCEPTION_TYPE_LISTBOX_ITEMS"
            :toggle-text="selectedExceptionTypeText"
            :selected="selectedExceptionType"
            @select="selectExceptionType"
          />
        </template>

        <template #projectSelector>
          <group-projects-dropdown
            v-if="showGroupProjectsDropdown"
            :group-full-path="namespacePath"
            :selected="projectIds"
            @projects-query-error="setShowAlert($options.i18n.groupProjectErrorDescription)"
            @select="setSelectedProjectIds"
          />
        </template>
      </gl-sprintf>
    </div>
  </div>
</template>

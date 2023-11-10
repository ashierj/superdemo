<script>
import { GlAlert, GlCollapsibleListbox, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
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
} from './constants';

export default {
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
  },
  name: 'PolicyScope',
  components: {
    GlAlert,
    GlCollapsibleListbox,
    ComplianceFrameworkDropdown,
    GlSprintf,
    GroupProjectsDropdown,
  },
  inject: ['namespacePath', 'rootNamespacePath'],
  data() {
    return {
      selectedProjectScopeType: PROJECTS_WITH_FRAMEWORK,
      selectedExceptionType: WITHOUT_EXCEPTIONS,
      selectedProjectIds: [],
      selectedFrameworkIds: [],
      showAlert: false,
      errorDescription: '',
    };
  },
  computed: {
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
    policyScopeCopy() {
      return this.selectedProjectScopeType === PROJECTS_WITH_FRAMEWORK
        ? this.$options.i18n.policyScopeFrameworkCopy
        : this.$options.i18n.policyScopeProjectCopy;
    },
  },
  methods: {
    selectProjectScopeType(scopeType) {
      this.selectedProjectScopeType = scopeType;
    },
    selectExceptionType(type) {
      this.selectedExceptionType = type;
    },
    setSelectedProjectIds(ids) {
      this.selectedProjectIds = ids;
    },
    setSelectedFrameworkIds(ids) {
      this.selectedFrameworkIds = ids;
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
            :items="$options.PROJECT_SCOPE_TYPE_LISTBOX_ITEMS"
            :selected="selectedProjectScopeType"
            :toggle-text="selectedProjectScopeText"
            @select="selectProjectScopeType"
          />
        </template>

        <template #frameworkSelector>
          <compliance-framework-dropdown
            :selected-framework-ids="selectedFrameworkIds"
            :full-path="rootNamespacePath"
            @framework-query-error="setShowAlert($options.i18n.complianceFrameworkErrorDescription)"
            @select="setSelectedFrameworkIds"
          />
        </template>

        <template #exceptionType>
          <gl-collapsible-listbox
            v-if="showExceptionTypeDropdown"
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
            :selected-projects-ids="selectedProjectIds"
            @projects-query-error="setShowAlert($options.i18n.groupProjectErrorDescription)"
            @select="setSelectedProjectIds"
          />
        </template>
      </gl-sprintf>
    </div>
  </div>
</template>

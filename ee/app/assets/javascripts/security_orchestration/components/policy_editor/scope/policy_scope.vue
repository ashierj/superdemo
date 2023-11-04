<script>
import { GlCollapsibleListbox, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  PROJECTS_WITH_FRAMEWORK,
  PROJECT_SCOPE_TYPE_LISTBOX,
  PROJECT_SCOPE_TYPE_LISTBOX_TEXTS,
} from './constants';

export default {
  PROJECT_SCOPE_TYPE_LISTBOX,
  PROJECT_SCOPE_TYPE_LISTBOX_TEXTS,
  i18n: {
    policyScopeCopy: s__(
      `SecurityOrchestration|Apply this policy to all projects %{projectScopeType} named %{exceptionType} %{projectSelector}`,
    ),
  },
  name: 'PolicyScope',
  components: {
    GlCollapsibleListbox,
    GlSprintf,
  },
  data() {
    return {
      selectedProjectScopeType: PROJECTS_WITH_FRAMEWORK,
    };
  },
  computed: {
    selectedProjectScopeText() {
      return PROJECT_SCOPE_TYPE_LISTBOX_TEXTS[this.selectedProjectScopeType];
    },
  },
  methods: {
    selectProjectScopeType(scopeType) {
      this.selectedProjectScopeType = scopeType;
    },
  },
};
</script>

<template>
  <div class="gl-mt-2 gl-mb-6">
    <gl-sprintf :message="$options.i18n.policyScopeCopy">
      <template #projectScopeType>
        <gl-collapsible-listbox
          :items="$options.PROJECT_SCOPE_TYPE_LISTBOX"
          :selected="selectedProjectScopeType"
          :toggle-text="selectedProjectScopeText"
          @select="selectProjectScopeType"
        />
      </template>

      <template #exceptionType> </template>

      <template #projectSelector> </template>
    </gl-sprintf>
  </div>
</template>

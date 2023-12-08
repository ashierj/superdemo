<script>
import {
  GlFormGroup,
  GlFormInputGroup,
  GlInputGroupText,
  GlSprintf,
  GlFormInput,
  GlTruncate,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RefSelector from '~/ref/components/ref_selector.vue';
import CodeBlockSourceSelector from 'ee/security_orchestration/components/policy_editor/scan_execution/action/code_block_source_selector.vue';
import GroupProjectsDropdown from 'ee/security_orchestration/components/group_projects_dropdown.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

export default {
  i18n: {
    filePathInputCopy: s__('ScanExecutionPolicy|%{labelStart}File path:%{labelEnd} %{filePath}'),
    filePathCopy: s__(
      'ScanExecutionPolicy|%{boldStart}Run%{boldEnd} %{typeSelector} from the project %{projectSelector} with ref %{refSelector}',
    ),
    filePathPrependLabel: __('Select project'),
    fileRefLabel: s__('ScanExecutionPolicy|Select ref'),
    filePathInputPlaceholder: s__('ScanExecutionPolicy|Link existing CI file'),
    filePathInputValidationMessage: s__("ScanExecutionPolicy|The file path can't be empty"),
    formGroupLabel: s__('ScanExecutionPolicy|file path group'),
  },
  name: 'CodeBlockFilePath',
  components: {
    CodeBlockSourceSelector,
    GlFormGroup,
    GlFormInputGroup,
    GlFormInput,
    GlInputGroupText,
    GlSprintf,
    GlTruncate,
    GroupProjectsDropdown,
    RefSelector,
  },
  inject: ['namespacePath', 'rootNamespacePath', 'namespaceType'],
  props: {
    selectedType: {
      type: String,
      required: false,
      default: '',
    },
    filePath: {
      type: String,
      required: false,
      default: null,
    },
    selectedRef: {
      type: String,
      required: false,
      default: '',
    },
    selectedProject: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    isValidFilePath() {
      if (this.filePath === null) {
        return null;
      }

      return Boolean(this.filePath);
    },
    selectedProjectId() {
      return this.selectedProject?.id;
    },
    selectedProjectIdShortFormat() {
      const value = getIdFromGraphQLId(this.selectedProjectId);
      return value ? value.toString() : '';
    },
    selectedProjectFullPath() {
      return this.selectedProject?.fullPath || this.$options.i18n.filePathPrependLabel;
    },
    groupProjectsPath() {
      return this.namespaceType === NAMESPACE_TYPES.GROUP
        ? this.namespacePath
        : this.rootNamespacePath;
    },
  },
  methods: {
    updatedFilePath(value) {
      this.$emit('update-file-path', value);
    },
    setSelectedProject(project) {
      this.$emit('select-project', project);
    },
    setSelectedType(type) {
      this.$emit('select-type', type);
    },
    setSelectedRef(ref) {
      this.$emit('select-ref', ref);
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-w-full gl-flex-direction-column gl-gap-3">
    <div class="gl-display-flex gl-gap-3 gl-align-items-center gl-flex-wrap">
      <gl-sprintf :message="$options.i18n.filePathCopy">
        <template #bold="{ content }">
          <b>{{ content }}</b>
        </template>

        <template #typeSelector>
          <code-block-source-selector :selected-type="selectedType" @select="setSelectedType" />
        </template>

        <template #projectSelector>
          <group-projects-dropdown
            class="gl-max-w-20"
            :group-full-path="groupProjectsPath"
            :selected="selectedProjectId"
            :multiple="false"
            @select="setSelectedProject"
          />
        </template>

        <template #refSelector>
          <ref-selector
            v-if="selectedProjectId"
            class="gl-max-w-20"
            :disabled="!selectedProjectId"
            :project-id="selectedProjectIdShortFormat"
            :value="selectedRef"
            @input="setSelectedRef"
          />

          <gl-form-input
            v-else
            class="gl-w-auto"
            :placeholder="$options.i18n.fileRefLabel"
            :value="selectedRef"
            @input="setSelectedRef"
          />
        </template>
      </gl-sprintf>
    </div>

    <div class="gl-display-flex gl-w-full gl-gap-3 gl-align-items-baseline gl-flex-nowrap">
      <gl-sprintf :message="$options.i18n.filePathInputCopy">
        <template #label="{ content }">
          <span class="gl-white-space-nowrap">{{ content }}</span>
        </template>

        <template #filePath>
          <gl-form-group
            class="gl-w-full gl-mb-0"
            label-sr-only
            :label="$options.i18n.formGroupLabel"
            :optional="false"
            :invalid-feedback="$options.i18n.filePathInputValidationMessage"
            :state="isValidFilePath"
          >
            <gl-form-input-group
              id="file-path"
              :placeholder="$options.i18n.filePathInputPlaceholder"
              :state="isValidFilePath"
              :value="filePath"
              @input="updatedFilePath"
            >
              <template #prepend>
                <gl-input-group-text class="gl-max-w-15 gl-max-h-full!">
                  <gl-truncate :text="selectedProjectFullPath" with-tooltip />
                </gl-input-group-text>
              </template>
            </gl-form-input-group>
          </gl-form-group>
        </template>
      </gl-sprintf>
    </div>
  </div>
</template>

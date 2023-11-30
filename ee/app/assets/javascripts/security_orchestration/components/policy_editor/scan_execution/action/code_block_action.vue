<script>
import { GlCollapsibleListbox, GlFormGroup, GlFormInput, GlSprintf } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import PolicyPopover from 'ee/security_orchestration/components/policy_popover.vue';
import SectionLayout from '../../section_layout.vue';
import { ACTION_AND_LABEL } from '../../constants';
import {
  CUSTOM_ACTION_KEY,
  CUSTOM_ACTION_OPTIONS,
  CUSTOM_ACTION_OPTIONS_LISTBOX_ITEMS,
  CUSTOM_ACTION_OPTIONS_KEYS,
  LINKED_EXISTING_FILE,
} from '../constants';
import CodeBlockImport from './code_block_import.vue';

export default {
  SCAN_EXECUTION_PATH: helpPagePath('user/application_security/policies/scan-execution-policies', {
    anchor: 'scan-action-type',
  }),
  ACTION_AND_LABEL,
  CUSTOM_ACTION_OPTIONS_KEYS,
  CUSTOM_ACTION_OPTIONS_LISTBOX_ITEMS,
  i18n: {
    customSectionHeaderCopy: s__(
      'ScanExecutionPolicy|%{boldStart}Run%{boldEnd} %{typeSelector} %{filePath} %{tooltip}',
    ),
    customSectionTypeLabel: s__('ScanExecutionPolicy|Choose a method to execute code'),
    linkedFileInputPlaceholder: s__('ScanExecutionPolicy|Link existing CI file'),
    linkedFileInputValidationMessage: s__("ScanExecutionPolicy|The file path can't be empty"),
    customSectionPopoverTitle: __('Information'),
    customSectionPopoverContent: s__(
      'ScanExecutionPolicy|If there are any conflicting variables with the local pipeline configuration (Ex, gitlab-ci.yml) then variables defined here will take precedence. %{linkStart}Learn more%{linkEnd}.',
    ),
  },
  name: 'CodeBlockAction',
  components: {
    PolicyPopover,
    CodeBlockImport,
    GlCollapsibleListbox,
    GlFormInput,
    GlFormGroup,
    GlSprintf,
    SectionLayout,
    YamlEditor: () =>
      import(
        /* webpackChunkName: 'policy_yaml_editor' */ 'ee/security_orchestration/components/yaml_editor.vue'
      ),
  },
  props: {
    actionIndex: {
      type: Number,
      required: false,
      default: 0,
    },
    initAction: {
      type: Object,
      required: true,
    },
  },
  data() {
    const hasFilePath = Boolean(this.initAction?.ci_configuration_path?.file);

    return {
      selectedType: hasFilePath ? LINKED_EXISTING_FILE : '',
      yamlEditorValue: '',
    };
  },
  computed: {
    filePath() {
      return this.initAction?.ci_configuration_path?.file;
    },
    hasExistingCode() {
      return Boolean(this.yamlEditorValue.length);
    },
    isFirstAction() {
      return this.actionIndex === 0;
    },
    isLinkedFile() {
      return this.selectedType === LINKED_EXISTING_FILE;
    },
    toggleText() {
      return CUSTOM_ACTION_OPTIONS[this.selectedType] || this.$options.i18n.customSectionTypeLabel;
    },
    isValidFilePath() {
      if (this.filePath === undefined) {
        return undefined;
      }

      return Boolean(this.filePath);
    },
  },
  methods: {
    resetActionToDefault() {
      this.$emit('changed', { scan: CUSTOM_ACTION_KEY });
    },
    setSelectedType(type) {
      this.selectedType = type;
      this.resetActionToDefault();
    },
    updateYaml(val) {
      this.yamlEditorValue = val;
    },
    updatedFilePath(path) {
      this.triggerChanged({
        ci_configuration_path: {
          file: path,
        },
      });
    },
    triggerChanged(value) {
      this.$emit('changed', { ...this.initAction, ...value });
    },
  },
};
</script>

<template>
  <div>
    <div
      v-if="!isFirstAction"
      class="gl-text-gray-500 gl-mb-4 gl-ml-5"
      data-testid="action-and-label"
    >
      {{ $options.ACTION_AND_LABEL }}
    </div>

    <section-layout @remove="$emit('remove')">
      <template #content>
        <div class="gl-display-inline-flex gl-w-full gl-gap-3 gl-align-items-center gl-flex-wrap">
          <div
            class="gl-display-inline-flex gl-w-full gl-gap-3 gl-align-items-baseline gl-flex-wrap gl-md-flex-nowrap"
          >
            <gl-sprintf :message="$options.i18n.customSectionHeaderCopy">
              <template #bold="{ content }">
                <b>{{ content }}</b>
              </template>

              <template #typeSelector>
                <gl-collapsible-listbox
                  label-for="file-path"
                  :items="$options.CUSTOM_ACTION_OPTIONS_LISTBOX_ITEMS"
                  :toggle-text="toggleText"
                  :selected="selectedType"
                  @select="setSelectedType"
                />
              </template>

              <template #filePath>
                <gl-form-group
                  v-if="isLinkedFile"
                  class="gl-w-full gl-mb-0"
                  label-sr-only
                  :label="__('file path group')"
                  :optional="false"
                  :invalid-feedback="$options.i18n.linkedFileInputValidationMessage"
                  :state="isValidFilePath"
                >
                  <gl-form-input
                    id="file-path"
                    :placeholder="$options.i18n.linkedFileInputPlaceholder"
                    :state="isValidFilePath"
                    :value="filePath"
                    @input="updatedFilePath"
                  />
                </gl-form-group>
              </template>

              <template #tooltip>
                <policy-popover
                  :content="$options.i18n.customSectionPopoverContent"
                  :title="$options.i18n.customSectionPopoverTitle"
                  :href="$options.SCAN_EXECUTION_PATH"
                  target="code-block-action-icon"
                />
              </template>
            </gl-sprintf>
          </div>
        </div>
        <div
          v-if="!isLinkedFile"
          class="editor gl-w-full gl-overflow-y-auto gl-rounded-base gl-h-200!"
        >
          <yaml-editor
            data-testid="custom-yaml-editor"
            policy-type="scan_execution_policy"
            :disable-schema="true"
            :value="yamlEditorValue"
            :read-only="false"
            @input="updateYaml"
          />
        </div>
        <code-block-import :has-existing-code="hasExistingCode" @changed="updateYaml" />
      </template>
    </section-layout>
  </div>
</template>

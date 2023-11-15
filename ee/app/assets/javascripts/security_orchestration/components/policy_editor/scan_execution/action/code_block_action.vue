<script>
import { GlCollapsibleListbox, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import SectionLayout from '../../section_layout.vue';
import { ACTION_AND_LABEL } from '../../constants';
import {
  CUSTOM_ACTION_OPTIONS,
  CUSTOM_ACTION_OPTIONS_LISTBOX_ITEMS,
  CUSTOM_ACTION_OPTIONS_KEYS,
} from '../constants';
import CodeBlockActionTooltip from './code_block_action_tooltip.vue';

export default {
  ACTION_AND_LABEL,
  CUSTOM_ACTION_OPTIONS_KEYS,
  CUSTOM_ACTION_OPTIONS_LISTBOX_ITEMS,
  i18n: {
    customSectionHeaderCopy: s__(
      'ScanExecutionPolicy|%{boldStart}Run%{boldEnd} %{typeSelector} %{tooltip}',
    ),
    customSectionTypeLabel: s__('ScanExecutionPolicy|Choose a method to execute code'),
  },
  name: 'CodeBlockAction',
  components: {
    CodeBlockActionTooltip,
    GlCollapsibleListbox,
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
    return {
      selectedType: '',
      yamlEditorValue: '',
    };
  },
  computed: {
    isFirstAction() {
      return this.actionIndex === 0;
    },
    toggleText() {
      return CUSTOM_ACTION_OPTIONS[this.selectedType] || this.$options.i18n.customSectionTypeLabel;
    },
  },
  methods: {
    setSelectedType(type) {
      this.selectedType = type;
    },
    updateYaml(val) {
      this.yamlEditorValue = val;
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
        <div class="gl-display-inline-flex gl-gap-3 gl-align-items-center gl-flex-wrap">
          <gl-sprintf :message="$options.i18n.customSectionHeaderCopy">
            <template #bold="{ content }">
              <b>{{ content }}</b>
            </template>

            <template #typeSelector>
              <gl-collapsible-listbox
                :items="$options.CUSTOM_ACTION_OPTIONS_LISTBOX_ITEMS"
                :toggle-text="toggleText"
                :selected="selectedType"
                @select="setSelectedType"
              />
            </template>

            <template #tooltip>
              <code-block-action-tooltip />
            </template>
          </gl-sprintf>
        </div>
        <div class="editor gl-w-full gl-overflow-y-auto gl-rounded-base gl-h-200!">
          <yaml-editor
            data-testid="custom-yaml-editor"
            policy-type="scan_execution_policy"
            :file-global-id="`${actionIndex}-code-block`"
            :value="yamlEditorValue"
            :read-only="false"
            @input="updateYaml"
          />
        </div>
      </template>
    </section-layout>
  </div>
</template>

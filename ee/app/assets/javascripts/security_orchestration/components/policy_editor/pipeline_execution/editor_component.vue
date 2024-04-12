<script>
import { GlEmptyState } from '@gitlab/ui';
import { setUrlFragment } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import {
  EDITOR_MODE_RULE,
  EDITOR_MODE_YAML,
  PARSING_ERROR_MESSAGE,
  SECURITY_POLICY_ACTIONS,
  ACTIONS_LABEL,
} from '../constants';
import EditorLayout from '../editor_layout.vue';
import DimDisableContainer from '../dim_disable_container.vue';
import RuleSection from './rule/rule_section.vue';
import ActionSection from './action/action_section.vue';
import { createPolicyObject, policyToYaml } from './utils';
import { CONDITIONS_LABEL, DEFAULT_PIPELINE_EXECUTION_POLICY } from './constants';

export default {
  ACTION: 'actions',
  EDITOR_MODE_RULE,
  EDITOR_MODE_YAML,
  SECURITY_POLICY_ACTIONS,
  i18n: {
    ACTIONS_LABEL,
    CONDITIONS_LABEL,
    PARSING_ERROR_MESSAGE,
    notOwnerButtonText: __('Learn more'),
  },
  components: {
    ActionSection,
    DimDisableContainer,
    GlEmptyState,
    EditorLayout,
    RuleSection,
  },
  inject: [
    'disableScanPolicyUpdate',
    'policyEditorEmptyStateSvgPath',
    'scanPolicyDocumentationPath',
  ],
  props: {
    assignedPolicyProject: {
      type: Object,
      required: true,
    },
    existingPolicy: {
      type: Object,
      required: false,
      default: null,
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    let yamlEditorValue;

    if (this.existingPolicy) {
      yamlEditorValue = policyToYaml(this.existingPolicy);
    } else {
      yamlEditorValue = DEFAULT_PIPELINE_EXECUTION_POLICY;
    }

    const { policy, hasParsingError } = createPolicyObject(yamlEditorValue);
    const parsingError = hasParsingError ? this.$options.i18n.PARSING_ERROR_MESSAGE : '';

    return {
      policy,
      hasParsingError,
      parsingError,
      yamlEditorValue,
      mode: EDITOR_MODE_RULE,
      documentationPath: setUrlFragment(
        this.scanPolicyDocumentationPath,
        'pipeline-execution-policy-editor',
      ),
    };
  },
  computed: {
    originalName() {
      return this.existingPolicy?.name;
    },
  },
  methods: {
    changeEditorMode(mode) {
      this.mode = mode;
    },
    handleUpdateProperty(property, value) {
      this.policy[property] = value;
      this.updateYamlEditorValue(this.policy);
    },
    handleUpdateYaml(manifest) {
      const { policy, hasParsingError } = createPolicyObject(manifest);

      this.yamlEditorValue = manifest;
      this.hasParsingError = hasParsingError;
      this.parsingError = hasParsingError ? this.$options.i18n.PARSING_ERROR_MESSAGE : '';
      this.policy = policy;
    },
    updateYamlEditorValue(policy) {
      this.yamlEditorValue = policyToYaml(policy);
    },
  },
};
</script>

<template>
  <editor-layout
    v-if="!disableScanPolicyUpdate"
    :has-parsing-error="hasParsingError"
    :is-editing="isEditing"
    :parsing-error="parsingError"
    :policy="policy"
    :yaml-editor-value="yamlEditorValue"
    @update-editor-mode="changeEditorMode"
    @update-property="handleUpdateProperty"
    @update-yaml="handleUpdateYaml"
  >
    <template #rules>
      <dim-disable-container :disabled="hasParsingError">
        <template #title>
          <h4>{{ $options.i18n.CONDITIONS_LABEL }}</h4>
        </template>

        <template #disabled>
          <div class="gl-bg-gray-10 gl-rounded-base gl-p-6"></div>
        </template>

        <rule-section class="gl-mb-4" />
      </dim-disable-container>
    </template>

    <template #actions-first>
      <dim-disable-container :disabled="hasParsingError">
        <template #title>
          <h4>{{ $options.i18n.ACTIONS_LABEL }}</h4>
        </template>

        <template #disabled>
          <div class="gl-bg-gray-10 gl-rounded-base gl-p-6"></div>
        </template>

        <action-section
          v-for="(action, index) in policy.actions"
          :key="action.id"
          :data-testid="`action-${index}`"
          :action-index="index"
          :init-action="action"
        />
      </dim-disable-container>
    </template>
  </editor-layout>

  <gl-empty-state
    v-else
    :description="$options.i18n.notOwnerDescription"
    :primary-button-link="documentationPath"
    :primary-button-text="$options.i18n.notOwnerButtonText"
    :svg-path="policyEditorEmptyStateSvgPath"
    :svg-height="null"
    title=""
  />
</template>

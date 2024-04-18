import { GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from 'ee/security_orchestration/constants';
import EditorComponent from 'ee/security_orchestration/components/policy_editor/pipeline_execution/editor_component.vue';
import ActionSection from 'ee/security_orchestration/components/policy_editor/pipeline_execution/action/action_section.vue';
import RuleSection from 'ee/security_orchestration/components/policy_editor/pipeline_execution/rule/rule_section.vue';
import EditorLayout from 'ee/security_orchestration/components/policy_editor/editor_layout.vue';
import { DEFAULT_PIPELINE_EXECUTION_POLICY } from 'ee/security_orchestration/components/policy_editor/pipeline_execution/constants';

import { configFileManifest, configFileObject } from './mock_data';

describe('EditorComponent', () => {
  let wrapper;
  const policyEditorEmptyStateSvgPath = 'path/to/svg';
  const scanPolicyDocumentationPath = 'path/to/docs';

  const factory = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(EditorComponent, {
      propsData: {
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        ...propsData,
      },
      provide: {
        disableScanPolicyUpdate: false,
        policyEditorEmptyStateSvgPath,
        scanPolicyDocumentationPath,
        ...provide,
      },
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPolicyEditorLayout = () => wrapper.findComponent(EditorLayout);
  const findActionSection = () => wrapper.findComponent(ActionSection);
  const findRuleSection = () => wrapper.findComponent(RuleSection);

  describe('rule mode', () => {
    it('renders the editor', () => {
      factory();
      expect(findPolicyEditorLayout().exists()).toBe(true);
      expect(findActionSection().exists()).toBe(true);
      expect(findRuleSection().exists()).toBe(true);
      expect(findEmptyState().exists()).toBe(false);
    });

    it('renders the default policy editor layout', () => {
      factory();
      const editorLayout = findPolicyEditorLayout();
      expect(editorLayout.exists()).toBe(true);
      expect(editorLayout.props()).toEqual(
        expect.objectContaining({
          yamlEditorValue: DEFAULT_PIPELINE_EXECUTION_POLICY,
        }),
      );
    });

    it('updates the general policy properties', async () => {
      const name = 'New name';
      factory();
      expect(findPolicyEditorLayout().props('policy').name).toBe('');
      expect(findPolicyEditorLayout().props('yamlEditorValue')).toContain("name: ''");
      await findPolicyEditorLayout().vm.$emit('update-property', 'name', name);
      expect(findPolicyEditorLayout().props('policy').name).toBe(name);
      expect(findPolicyEditorLayout().props('yamlEditorValue')).toContain(`name: ${name}`);
    });
  });

  describe('yaml mode', () => {
    it('updates the policy', async () => {
      factory();
      await findPolicyEditorLayout().vm.$emit('update-yaml', configFileManifest);
      expect(findPolicyEditorLayout().props('policy')).toEqual(configFileObject);
      expect(findPolicyEditorLayout().props('yamlEditorValue')).toBe(configFileManifest);
    });
  });

  describe('empty page', () => {
    it('renders', () => {
      factory({ provide: { disableScanPolicyUpdate: true } });
      expect(findPolicyEditorLayout().exists()).toBe(false);
      expect(findActionSection().exists()).toBe(false);
      expect(findRuleSection().exists()).toBe(false);

      const emptyState = findEmptyState();
      expect(emptyState.exists()).toBe(true);
      expect(emptyState.props('primaryButtonLink')).toMatch(scanPolicyDocumentationPath);
      expect(emptyState.props('primaryButtonLink')).toMatch('pipeline-execution-policy-editor');
      expect(emptyState.props('svgPath')).toBe(policyEditorEmptyStateSvgPath);
    });
  });
});

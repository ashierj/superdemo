import { GlEmptyState } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { nextTick } from 'vue';
import EditorComponent from 'ee/security_orchestration/components/policy_editor/scan_execution/editor_component.vue';
import ActionSection from 'ee/security_orchestration/components/policy_editor/scan_execution/action/action_section.vue';
import RuleSection from 'ee/security_orchestration/components/policy_editor/scan_execution/rule/rule_section.vue';
import ActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_execution/action/scan_action.vue';
import ScanFilterSelector from 'ee/security_orchestration/components/policy_editor/scan_filter_selector.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EditorLayout from 'ee/security_orchestration/components/policy_editor/editor_layout.vue';
import {
  DEFAULT_SCAN_EXECUTION_POLICY_WITH_SCOPE,
  DEFAULT_SCAN_EXECUTION_POLICY,
  buildScannerAction,
  fromYaml,
  createPolicyObject,
} from 'ee/security_orchestration/components/policy_editor/scan_execution/lib';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from 'ee/security_orchestration/constants';
import {
  mockDastScanExecutionManifest,
  mockDastScanExecutionObject,
} from 'ee_jest/security_orchestration/mocks/mock_scan_execution_policy_data';
import { visitUrl } from '~/lib/utils/url_utility';

import { modifyPolicy } from 'ee/security_orchestration/components/policy_editor/utils';
import { SECURITY_POLICY_ACTIONS } from 'ee/security_orchestration/components/policy_editor/constants';
import {
  DEFAULT_SCANNER,
  SCAN_EXECUTION_PIPELINE_RULE,
  POLICY_ACTION_BUILDER_TAGS_ERROR_KEY,
  POLICY_ACTION_BUILDER_DAST_PROFILES_ERROR_KEY,
  RUNNER_TAGS_PARSING_ERROR,
  DAST_SCANNERS_PARSING_ERROR,
  EXECUTE_YAML_ACTION,
} from 'ee/security_orchestration/components/policy_editor/scan_execution/constants';
import { RULE_KEY_MAP } from 'ee/security_orchestration/components/policy_editor/scan_execution/lib/rules';

jest.mock('lodash/uniqueId');

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

const newlyCreatedPolicyProject = {
  branch: 'main',
  fullPath: 'path/to/new-project',
};

jest.mock('ee/security_orchestration/components/policy_editor/utils', () => ({
  ...jest.requireActual('ee/security_orchestration/components/policy_editor/utils'),
  assignSecurityPolicyProject: jest.fn().mockResolvedValue({
    branch: 'main',
    fullPath: 'path/to/new-project',
  }),
  modifyPolicy: jest.fn().mockResolvedValue({ id: '2' }),
}));

describe('EditorComponent', () => {
  let wrapper;
  const defaultProjectPath = 'path/to/project';
  const policyEditorEmptyStateSvgPath = 'path/to/svg';
  const scanPolicyDocumentationPath = 'path/to/docs';
  const assignedPolicyProject = {
    branch: 'main',
    fullPath: 'path/to/existing-project',
  };

  const factory = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(EditorComponent, {
      propsData: {
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        ...propsData,
      },
      provide: {
        disableScanPolicyUpdate: false,
        policyEditorEmptyStateSvgPath,
        namespacePath: defaultProjectPath,
        scanPolicyDocumentationPath,
        customCiToggleEnabled: true,
        ...provide,
      },
    });
  };

  const factoryWithExistingPolicy = () => {
    return factory({
      propsData: {
        assignedPolicyProject,
        existingPolicy: mockDastScanExecutionObject,
        isEditing: true,
      },
    });
  };

  const findAddActionButton = () => wrapper.findByTestId('add-action');
  const findAddRuleButton = () => wrapper.findByTestId('add-rule');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPolicyEditorLayout = () => wrapper.findComponent(EditorLayout);
  const findActionBuilder = () => wrapper.findComponent(ActionBuilder);
  const findAllActionBuilders = () => wrapper.findAllComponents(ActionBuilder);
  const findRuleSection = () => wrapper.findComponent(RuleSection);
  const findAllRuleSections = () => wrapper.findAllComponents(RuleSection);
  const findScanFilterSelector = () => wrapper.findComponent(ScanFilterSelector);
  const findActionSection = () => wrapper.findComponent(ActionSection);
  const findAllActionSections = () => wrapper.findAllComponents(ActionSection);

  beforeEach(() => {
    uniqueId.mockImplementation(jest.fn((prefix) => `${prefix}0`));
  });

  describe('default', () => {
    beforeEach(() => {
      factory();
    });

    it('should render correctly', () => {
      expect(findPolicyEditorLayout().props()).toMatchObject({
        hasParsingError: false,
        parsingError: '',
      });
    });
  });

  describe('saving a policy', () => {
    it.each`
      status                            | action                             | event              | factoryFn                    | yamlEditorValue                  | currentlyAssignedPolicyProject
      ${'to save a new policy'}         | ${SECURITY_POLICY_ACTIONS.APPEND}  | ${'save-policy'}   | ${factory}                   | ${DEFAULT_SCAN_EXECUTION_POLICY} | ${newlyCreatedPolicyProject}
      ${'to update an existing policy'} | ${SECURITY_POLICY_ACTIONS.REPLACE} | ${'save-policy'}   | ${factoryWithExistingPolicy} | ${mockDastScanExecutionManifest} | ${assignedPolicyProject}
      ${'to delete an existing policy'} | ${SECURITY_POLICY_ACTIONS.REMOVE}  | ${'remove-policy'} | ${factoryWithExistingPolicy} | ${mockDastScanExecutionManifest} | ${assignedPolicyProject}
    `(
      'navigates to the new merge request when "modifyPolicy" is emitted $status',
      async ({ action, event, factoryFn, yamlEditorValue, currentlyAssignedPolicyProject }) => {
        factoryFn();
        await nextTick();
        findPolicyEditorLayout().vm.$emit(event);
        await waitForPromises();
        expect(modifyPolicy).toHaveBeenCalledTimes(1);
        expect(modifyPolicy).toHaveBeenCalledWith({
          action,
          assignedPolicyProject: currentlyAssignedPolicyProject,
          name:
            action === SECURITY_POLICY_ACTIONS.APPEND
              ? fromYaml({ manifest: yamlEditorValue }).name
              : mockDastScanExecutionObject.name,
          namespacePath: defaultProjectPath,
          yamlEditorValue,
        });
        await nextTick();
        expect(visitUrl).toHaveBeenCalled();
        expect(visitUrl).toHaveBeenCalledWith(
          `/${currentlyAssignedPolicyProject.fullPath}/-/merge_requests/2`,
        );
      },
    );
  });

  describe('when a user is not an owner of the project', () => {
    it('displays the empty state with the appropriate properties', async () => {
      factory({ provide: { disableScanPolicyUpdate: true } });
      await nextTick();
      const emptyState = findEmptyState();

      expect(emptyState.props('primaryButtonLink')).toMatch(scanPolicyDocumentationPath);
      expect(emptyState.props('primaryButtonLink')).toMatch('scan-execution-policy-editor');
      expect(emptyState.props('svgPath')).toBe(policyEditorEmptyStateSvgPath);
    });
  });

  describe('modifying a policy', () => {
    beforeEach(factory);

    it('updates the yaml and policy object when "update-yaml" is emitted', async () => {
      const newManifest = `name: test
enabled: true`;

      expect(findPolicyEditorLayout().props()).toMatchObject({
        hasParsingError: false,
        parsingError: '',
        policy: fromYaml({ manifest: DEFAULT_SCAN_EXECUTION_POLICY }),
        yamlEditorValue: DEFAULT_SCAN_EXECUTION_POLICY,
      });
      findPolicyEditorLayout().vm.$emit('update-yaml', newManifest);
      await nextTick();
      expect(findPolicyEditorLayout().props()).toMatchObject({
        hasParsingError: false,
        parsingError: '',
        policy: expect.objectContaining({ enabled: true }),
        yamlEditorValue: newManifest,
      });
    });

    it.each`
      component        | oldValue | newValue
      ${'name'}        | ${''}    | ${'new policy name'}
      ${'description'} | ${''}    | ${'new description'}
      ${'enabled'}     | ${true}  | ${false}
    `('triggers a change on $component', async ({ component, newValue, oldValue }) => {
      expect(findPolicyEditorLayout().props('policy')[component]).toBe(oldValue);
      expect(findPolicyEditorLayout().props('yamlEditorValue')).toMatch(
        `${component}: ${oldValue}`,
      );

      findPolicyEditorLayout().vm.$emit('set-policy-property', component, newValue);
      await nextTick();

      expect(findPolicyEditorLayout().props('policy')[component]).toBe(newValue);
      expect(findPolicyEditorLayout().props('yamlEditorValue')).toMatch(
        `${component}: ${newValue}`,
      );
    });
  });

  describe('policy rule builder', () => {
    beforeEach(() => {
      uniqueId.mockRestore();
      factory();
    });

    it('should add new rule', async () => {
      const initialValue = [RULE_KEY_MAP[SCAN_EXECUTION_PIPELINE_RULE]()];
      expect(findPolicyEditorLayout().props('policy').rules).toStrictEqual(initialValue);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).rules,
      ).toStrictEqual(initialValue);
      expect(findAllRuleSections()).toHaveLength(1);

      findAddRuleButton().vm.$emit('click');
      await nextTick();

      const finalValue = [
        RULE_KEY_MAP[SCAN_EXECUTION_PIPELINE_RULE](),
        RULE_KEY_MAP[SCAN_EXECUTION_PIPELINE_RULE](),
      ];
      expect(findPolicyEditorLayout().props('policy').rules).toStrictEqual(finalValue);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).rules,
      ).toStrictEqual(finalValue);
      expect(findAllRuleSections()).toHaveLength(2);
    });

    it('should update rule', async () => {
      const initialValue = [RULE_KEY_MAP[SCAN_EXECUTION_PIPELINE_RULE]()];
      expect(findPolicyEditorLayout().props('policy').rules).toStrictEqual(initialValue);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).rules,
      ).toStrictEqual(initialValue);

      const finalValue = [{ ...RULE_KEY_MAP[SCAN_EXECUTION_PIPELINE_RULE](), branches: ['main'] }];
      findRuleSection().vm.$emit('changed', finalValue[0]);
      await nextTick();

      expect(findPolicyEditorLayout().props('policy').rules).toStrictEqual(finalValue);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).rules,
      ).toStrictEqual(finalValue);
    });

    it('should remove rule', async () => {
      findAddRuleButton().vm.$emit('click');
      await nextTick();

      expect(findAllRuleSections()).toHaveLength(2);
      expect(findPolicyEditorLayout().props('policy').rules).toHaveLength(2);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).rules,
      ).toHaveLength(2);

      findRuleSection().vm.$emit('remove', 1);
      await nextTick();

      expect(findAllRuleSections()).toHaveLength(1);
      expect(findPolicyEditorLayout().props('policy').rules).toHaveLength(1);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).rules,
      ).toHaveLength(1);
    });
  });

  describe('policy action builder', () => {
    beforeEach(() => {
      uniqueId.mockRestore();
      factory();
    });

    it('should add new action', async () => {
      const initialValue = [buildScannerAction({ scanner: DEFAULT_SCANNER })];
      expect(findPolicyEditorLayout().props('policy').actions).toStrictEqual(initialValue);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).actions,
      ).toStrictEqual(initialValue);

      findAddActionButton().vm.$emit('click');
      await nextTick();

      const finalValue = [
        buildScannerAction({ scanner: DEFAULT_SCANNER }),
        buildScannerAction({ scanner: DEFAULT_SCANNER }),
      ];
      expect(findPolicyEditorLayout().props('policy').actions).toStrictEqual(finalValue);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).actions,
      ).toStrictEqual(finalValue);
    });

    it('should update action', async () => {
      const initialValue = [buildScannerAction({ scanner: DEFAULT_SCANNER })];
      expect(findPolicyEditorLayout().props('policy').actions).toStrictEqual(initialValue);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).actions,
      ).toStrictEqual(initialValue);

      const finalValue = [buildScannerAction({ scanner: 'sast' })];
      findActionBuilder().vm.$emit('changed', finalValue[0]);
      await nextTick();

      expect(findPolicyEditorLayout().props('policy').actions).toStrictEqual(finalValue);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).actions,
      ).toStrictEqual(finalValue);
    });

    it('should remove action', async () => {
      findAddActionButton().vm.$emit('click');
      await nextTick();

      expect(findAllActionBuilders()).toHaveLength(2);
      expect(findPolicyEditorLayout().props('policy').actions).toHaveLength(2);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).actions,
      ).toHaveLength(2);

      findActionBuilder().vm.$emit('remove', 1);
      await nextTick();

      expect(findAllActionBuilders()).toHaveLength(1);
      expect(findPolicyEditorLayout().props('policy').actions).toHaveLength(1);
      expect(
        fromYaml({ manifest: findPolicyEditorLayout().props('yamlEditorValue') }).actions,
      ).toHaveLength(1);
    });
  });

  describe('parsing tags errors', () => {
    beforeEach(() => {
      factory();
    });

    it.each`
      name               | errorKey                                         | expectedErrorMessage
      ${'tags'}          | ${POLICY_ACTION_BUILDER_TAGS_ERROR_KEY}          | ${RUNNER_TAGS_PARSING_ERROR}
      ${'DAST profiles'} | ${POLICY_ACTION_BUILDER_DAST_PROFILES_ERROR_KEY} | ${DAST_SCANNERS_PARSING_ERROR}
    `(
      'disables rule editor when parsing of $name fails',
      async ({ errorKey, expectedErrorMessage }) => {
        findActionBuilder().vm.$emit('parsing-error', errorKey);
        await nextTick();
        expect(findPolicyEditorLayout().props('hasParsingError')).toBe(true);
        expect(findPolicyEditorLayout().props('parsingError')).toBe(expectedErrorMessage);
      },
    );
  });

  describe('execute yaml block section', () => {
    it.each([true, false])(
      'should render action builder when feature flag is enabled',
      (flagEnabled) => {
        factory({
          provide: {
            glFeatures: { compliancePipelineInPolicies: flagEnabled },
            customCiToggleEnabled: flagEnabled,
          },
        });

        expect(findActionSection().exists()).toBe(flagEnabled);
        expect(findScanFilterSelector().exists()).toBe(flagEnabled);
        expect(findAddActionButton().exists()).toBe(!flagEnabled);
      },
    );

    it('should add custom action', async () => {
      uniqueId.mockRestore();
      factory({
        provide: {
          glFeatures: { compliancePipelineInPolicies: true },
          customCiToggleEnabled: true,
        },
      });

      expect(findAllActionSections()).toHaveLength(1);

      await findScanFilterSelector().vm.$emit('select', EXECUTE_YAML_ACTION);

      expect(findAllActionSections()).toHaveLength(2);
    });
  });

  describe('policy scope', () => {
    it.each`
      securityPoliciesPolicyScope | manifest
      ${true}                     | ${DEFAULT_SCAN_EXECUTION_POLICY_WITH_SCOPE}
      ${false}                    | ${DEFAULT_SCAN_EXECUTION_POLICY}
    `('should render default policy', ({ securityPoliciesPolicyScope, manifest }) => {
      const features = {
        securityPoliciesPolicyScope,
      };
      window.gon = { features };

      factory({
        provide: {
          glFeatures: features,
        },
      });

      expect(findPolicyEditorLayout().props('policy')).toEqual(createPolicyObject(manifest).policy);
    });
  });
});

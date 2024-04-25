import { GlEmptyState } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SettingsSection from 'ee/security_orchestration/components/policy_editor/scan_result/settings/settings_section.vue';
import ScanFilterSelector from 'ee/security_orchestration/components/policy_editor/scan_filter_selector.vue';
import EditorLayout from 'ee/security_orchestration/components/policy_editor/editor_layout.vue';
import {
  SCAN_FINDING,
  ANY_MERGE_REQUEST,
  DEFAULT_SCAN_RESULT_POLICY,
  DEFAULT_SCAN_RESULT_POLICY_WITH_BOT_MESSAGE,
  DEFAULT_SCAN_RESULT_POLICY_WITH_SCOPE,
  getInvalidBranches,
  fromYaml,
  REQUIRE_APPROVAL_TYPE,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib';
import EditorComponent from 'ee/security_orchestration/components/policy_editor/scan_result/editor_component.vue';
import {
  DEFAULT_ASSIGNED_POLICY_PROJECT,
  NAMESPACE_TYPES,
  USER_TYPE,
} from 'ee/security_orchestration/constants';
import {
  mockDefaultBranchesScanResultManifest,
  mockDefaultBranchesScanResultObject,
  mockDeprecatedScanResultManifest,
  mockDeprecatedScanResultObject,
  mockBotMessageScanResultObject,
} from 'ee_jest/security_orchestration/mocks/mock_scan_result_policy_data';
import {
  unsupportedManifest,
  APPROVAL_POLICY_DEFAULT_POLICY,
  APPROVAL_POLICY_DEFAULT_POLICY_WITH_SCOPE,
  APPROVAL_POLICY_DEFAULT_POLICY_WITH_BOT_MESSAGE,
} from 'ee_jest/security_orchestration/mocks/mock_data';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  PERMITTED_INVALID_SETTINGS,
  BLOCK_BRANCH_MODIFICATION,
  PREVENT_PUSHING_AND_FORCE_PUSHING,
  PREVENT_APPROVAL_BY_AUTHOR,
  protectedBranchesConfiguration,
  pushingBranchesConfiguration,
  mergeRequestConfiguration,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib/settings';

import { modifyPolicy } from 'ee/security_orchestration/components/policy_editor/utils';
import {
  SECURITY_POLICY_ACTIONS,
  EDITOR_MODE_RULE,
  EDITOR_MODE_YAML,
  PARSING_ERROR_MESSAGE,
} from 'ee/security_orchestration/components/policy_editor/constants';
import DimDisableContainer from 'ee/security_orchestration/components/policy_editor/dim_disable_container.vue';
import ActionSection from 'ee/security_orchestration/components/policy_editor/scan_result/action/action_section.vue';
import ApproverAction from 'ee/security_orchestration/components/policy_editor/scan_result/action/approver_action.vue';
import RuleSection from 'ee/security_orchestration/components/policy_editor/scan_result/rule/rule_section.vue';

jest.mock('lodash/uniqueId');

jest.mock('ee/security_orchestration/components/policy_editor/scan_result/lib', () => ({
  ...jest.requireActual('ee/security_orchestration/components/policy_editor/scan_result/lib'),
  getInvalidBranches: jest.fn().mockResolvedValue([]),
}));

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
  const scanResultPolicyApprovers = {
    user: [{ id: 1, username: 'the.one', state: 'active' }],
    group: [],
    role: [],
  };

  const factory = ({ propsData = {}, provide = {}, glFeatures = {} } = {}) => {
    wrapper = shallowMountExtended(EditorComponent, {
      propsData: {
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        ...propsData,
      },
      provide: {
        disableScanPolicyUpdate: false,
        policyEditorEmptyStateSvgPath,
        namespaceId: 1,
        namespacePath: defaultProjectPath,
        namespaceType: NAMESPACE_TYPES.PROJECT,
        scanPolicyDocumentationPath,
        scanResultPolicyApprovers,
        glFeatures,
        ...provide,
      },
    });
  };

  const factoryWithExistingPolicy = ({
    policy = {},
    provide = {},
    hasActions = true,
    glFeatures = {},
  } = {}) => {
    const existingPolicy = { ...mockDefaultBranchesScanResultObject };

    if (!hasActions) {
      delete existingPolicy.actions;
    }

    return factory({
      propsData: {
        assignedPolicyProject,
        existingPolicy: { ...existingPolicy, ...policy },
        isEditing: true,
      },
      provide,
      glFeatures,
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPolicyEditorLayout = () => wrapper.findComponent(EditorLayout);
  const findActionSection = () => wrapper.findComponent(ActionSection);
  const findAllActionSections = () => wrapper.findAllComponents(ActionSection);
  const findApproverAction = () => wrapper.findComponent(ApproverAction);
  const findAllApproverActions = () => wrapper.findAllComponents(ApproverAction);
  const findAddActionButton = () => wrapper.findByTestId('add-action');
  const findAddRuleButton = () => wrapper.findByTestId('add-rule');
  const findAllDisabledComponents = () => wrapper.findAllComponents(DimDisableContainer);
  const findAllRuleSections = () => wrapper.findAllComponents(RuleSection);
  const findSettingsSection = () => wrapper.findComponent(SettingsSection);
  const findEmptyActionsAlert = () => wrapper.findByTestId('empty-actions-alert');
  const findScanFilterSelector = () => wrapper.findComponent(ScanFilterSelector);

  const changesToRuleMode = () =>
    findPolicyEditorLayout().vm.$emit('update-editor-mode', EDITOR_MODE_RULE);

  const changesToYamlMode = () =>
    findPolicyEditorLayout().vm.$emit('update-editor-mode', EDITOR_MODE_YAML);

  const verifiesParsingError = () => {
    expect(findPolicyEditorLayout().props('hasParsingError')).toBe(true);
    expect(findPolicyEditorLayout().attributes('parsingerror')).toBe(PARSING_ERROR_MESSAGE);
  };

  beforeEach(() => {
    getInvalidBranches.mockClear();
    uniqueId.mockImplementation(jest.fn((prefix) => `${prefix}0`));
  });

  describe('rendering', () => {
    it.each`
      namespaceType              | policy
      ${NAMESPACE_TYPES.GROUP}   | ${APPROVAL_POLICY_DEFAULT_POLICY_WITH_SCOPE}
      ${NAMESPACE_TYPES.PROJECT} | ${APPROVAL_POLICY_DEFAULT_POLICY}
    `('should render default policy for a $namespaceType', ({ namespaceType, policy }) => {
      factory({ provide: { namespaceType } });
      expect(findPolicyEditorLayout().props('policy')).toEqual(policy);
      expect(findPolicyEditorLayout().props('hasParsingError')).toBe(false);
    });

    it.each`
      namespaceType              | manifest
      ${NAMESPACE_TYPES.GROUP}   | ${DEFAULT_SCAN_RESULT_POLICY_WITH_SCOPE}
      ${NAMESPACE_TYPES.PROJECT} | ${DEFAULT_SCAN_RESULT_POLICY}
    `(
      'should use the correct default policy yaml for a $namespaceType',
      ({ namespaceType, manifest }) => {
        factory({ provide: { namespaceType } });
        expect(findPolicyEditorLayout().props('yamlEditorValue')).toBe(manifest);
      },
    );

    it('displays the initial rule and add rule button', () => {
      factory();
      expect(findAllRuleSections()).toHaveLength(1);
      expect(findAddRuleButton().exists()).toBe(true);
    });

    describe('when a user is not an owner of the project', () => {
      it('displays the empty state with the appropriate properties', () => {
        factory({ provide: { disableScanPolicyUpdate: true } });

        const emptyState = findEmptyState();

        expect(emptyState.props('primaryButtonLink')).toMatch(scanPolicyDocumentationPath);
        expect(emptyState.props('primaryButtonLink')).toMatch('scan-result-policy-editor');
        expect(emptyState.props('svgPath')).toBe(policyEditorEmptyStateSvgPath);
      });
    });

    describe('existing policy', () => {
      it('displays an approval policy', () => {
        factoryWithExistingPolicy();
        expect(findEmptyActionsAlert().exists()).toBe(false);
        expect(findPolicyEditorLayout().props('yamlEditorValue')).toBe(
          mockDefaultBranchesScanResultManifest,
        );
        expect(findAllRuleSections()).toHaveLength(1);
        expect(findAllApproverActions()).toHaveLength(1);
      });

      it('displays a scan result policy', () => {
        factoryWithExistingPolicy({ policy: mockDeprecatedScanResultObject });
        expect(findPolicyEditorLayout().props('hasParsingError')).toBe(false);
        expect(findPolicyEditorLayout().props('yamlEditorValue')).toBe(
          mockDeprecatedScanResultManifest,
        );
        expect(findAllRuleSections()).toHaveLength(1);
        expect(findAllApproverActions()).toHaveLength(1);
      });
    });
  });

  describe('rule mode updates', () => {
    describe('properties', () => {
      it.each`
        component         | oldValue     | newValue
        ${'name'}         | ${''}        | ${'new policy name'}
        ${'description'}  | ${''}        | ${'new description'}
        ${'enabled'}      | ${true}      | ${false}
        ${'policy_scope'} | ${undefined} | ${{ compliance_frameworks: [{ id: 'id1' }, { id: 'id2' }] }}
      `('updates the $component property', ({ component, newValue, oldValue }) => {
        factory();
        expect(findPolicyEditorLayout().props('policy')[component]).toEqual(oldValue);
        findPolicyEditorLayout().vm.$emit('update-property', component, newValue);
        expect(findPolicyEditorLayout().props('policy')[component]).toEqual(newValue);
      });

      it('removes the policy scope property', async () => {
        const oldValue = {
          policy_scope: { compliance_frameworks: [{ id: 'id1' }, { id: 'id2' }] },
        };

        factoryWithExistingPolicy({ policy: oldValue });
        expect(findPolicyEditorLayout().props('policy').policy_scope).toEqual(
          oldValue.policy_scope,
        );
        await findPolicyEditorLayout().vm.$emit('remove-property', 'policy_scope');
        expect(findPolicyEditorLayout().props('policy').policy_scope).toBe(undefined);
      });
    });

    describe('rule section', () => {
      it('adds a new rule', async () => {
        const rulesCount = 1;
        factory();
        expect(findAllRuleSections()).toHaveLength(rulesCount);
        await findAddRuleButton().vm.$emit('click');
        expect(findAllRuleSections()).toHaveLength(rulesCount + 1);
      });

      it('hides add button when the limit of five rules has been reached', () => {
        const limit = 5;
        const { id, ...rule } = mockDefaultBranchesScanResultObject.rules[0];
        uniqueId.mockRestore();
        factoryWithExistingPolicy({ policy: { rules: [rule, rule, rule, rule, rule] } });
        expect(findAllRuleSections()).toHaveLength(limit);
        expect(findAddRuleButton().exists()).toBe(false);
      });

      it('updates an existing rule', async () => {
        const newValue = {
          type: 'scan_finding',
          branches: [],
          scanners: [],
          vulnerabilities_allowed: 1,
          severity_levels: [],
          vulnerability_states: [],
        };
        factory();

        await findAllRuleSections().at(0).vm.$emit('changed', newValue);
        expect(findAllRuleSections().at(0).props('initRule')).toEqual(newValue);
        expect(findPolicyEditorLayout().props('policy').rules[0].vulnerabilities_allowed).toBe(1);
      });

      it('deletes the initial rule', async () => {
        const initialRuleCount = 1;
        factory();

        expect(findAllRuleSections()).toHaveLength(initialRuleCount);

        await findAllRuleSections().at(0).vm.$emit('remove', 0);

        expect(findAllRuleSections()).toHaveLength(initialRuleCount - 1);
      });

      describe('settings', () => {
        const defaultProjectApprovalConfiguration = {
          [PREVENT_PUSHING_AND_FORCE_PUSHING]: true,
          [BLOCK_BRANCH_MODIFICATION]: true,
        };

        it('updates the settings containing permitted invalid settings', () => {
          factoryWithExistingPolicy({
            policy: { approval_settings: PERMITTED_INVALID_SETTINGS },
          });
          expect(findPolicyEditorLayout().props('policy')).toEqual(
            expect.objectContaining({ approval_settings: PERMITTED_INVALID_SETTINGS }),
          );
          findAllRuleSections().at(0).vm.$emit('changed', { type: SCAN_FINDING });
          expect(findPolicyEditorLayout().props('policy')).toEqual(
            expect.objectContaining({
              approval_settings: {
                ...protectedBranchesConfiguration,
                ...pushingBranchesConfiguration,
              },
            }),
          );
        });

        it('updates the settings', () => {
          const newValue = { type: ANY_MERGE_REQUEST };
          factory();
          expect(findPolicyEditorLayout().props('policy')).toEqual(
            expect.objectContaining({
              approval_settings: defaultProjectApprovalConfiguration,
            }),
          );
          findAllRuleSections().at(0).vm.$emit('changed', newValue);
          expect(findPolicyEditorLayout().props('policy')).toEqual(
            expect.objectContaining({
              approval_settings: {
                ...defaultProjectApprovalConfiguration,
                ...mergeRequestConfiguration,
              },
            }),
          );
        });

        it('updates the settings containing permitted invalid values', () => {
          factoryWithExistingPolicy({ policy: { approval_settings: PERMITTED_INVALID_SETTINGS } });
          expect(findPolicyEditorLayout().props('policy')).toEqual(
            expect.objectContaining({
              approval_settings: PERMITTED_INVALID_SETTINGS,
            }),
          );
          findAllRuleSections().at(0).vm.$emit('changed', { type: SCAN_FINDING });
          expect(findPolicyEditorLayout().props('policy')).toEqual(
            expect.objectContaining({
              approval_settings: {
                ...protectedBranchesConfiguration,
                ...pushingBranchesConfiguration,
              },
            }),
          );
        });

        it('does update the settings with ANY_MERGE_REQUEST type', () => {
          const newValue = { type: ANY_MERGE_REQUEST };
          factory();
          expect(findPolicyEditorLayout().props('policy')).toEqual(
            expect.objectContaining({
              approval_settings: defaultProjectApprovalConfiguration,
            }),
          );
          findAllRuleSections().at(0).vm.$emit('changed', newValue);
          expect(findPolicyEditorLayout().props('policy')).toEqual(
            expect.objectContaining({
              approval_settings: {
                ...defaultProjectApprovalConfiguration,
                ...mergeRequestConfiguration,
              },
            }),
          );
        });
      });
    });

    describe('action section  when the "approvalPolicyDisableBotComment" feature is off', () => {
      describe('rendering', () => {
        it('displays the approver action when the "approvalPolicyDisableBotComment" feature is off', () => {
          factory();
          expect(findAllApproverActions()).toHaveLength(1);
          expect(findApproverAction().props('existingApprovers')).toEqual(
            scanResultPolicyApprovers,
          );
        });
      });

      describe('add', () => {
        it('hides the add button when actions exist', () => {
          factory();
          expect(findApproverAction().exists()).toBe(true);
          expect(findAddActionButton().exists()).toBe(false);
        });

        it('shows the add button when actions do not exist', () => {
          factoryWithExistingPolicy({ hasActions: false });
          expect(findApproverAction().exists()).toBe(false);
          expect(findAddActionButton().exists()).toBe(true);
        });
      });

      describe('remove', () => {
        it('removes the initial action', async () => {
          factory();
          expect(findApproverAction().exists()).toBe(true);
          expect(findPolicyEditorLayout().props('policy')).toHaveProperty('actions');
          await findApproverAction().vm.$emit('remove');
          expect(findApproverAction().exists()).toBe(false);
          expect(findPolicyEditorLayout().props('policy')).not.toHaveProperty('actions');
        });

        it('removes the action approvers when the action is removed', async () => {
          factory();
          await findApproverAction().vm.$emit(
            'changed',
            mockDefaultBranchesScanResultObject.actions[0],
          );
          await findApproverAction().vm.$emit('remove');
          await findAddActionButton().vm.$emit('click');
          expect(findPolicyEditorLayout().props('policy').actions).toEqual([
            {
              approvals_required: 1,
              type: 'require_approval',
              id: 'action_0',
            },
          ]);
          expect(findApproverAction().props('existingApprovers')).toEqual({});
        });
      });

      describe('update', () => {
        beforeEach(() => {
          factory();
        });

        it('updates policy action when edited', async () => {
          const UPDATED_ACTION = { type: 'required_approval', group_approvers_ids: [1] };
          await findApproverAction().vm.$emit('changed', UPDATED_ACTION);

          expect(findApproverAction().props('initAction')).toEqual(UPDATED_ACTION);
        });

        it('updates the policy approvers', async () => {
          const newApprover = ['owner'];

          await findApproverAction().vm.$emit('updateApprovers', {
            ...scanResultPolicyApprovers,
            role: newApprover,
          });

          expect(findApproverAction().props('existingApprovers')).toMatchObject({
            role: newApprover,
          });
        });

        it('creates an error when the action section emits one', async () => {
          await findApproverAction().vm.$emit('error');
          verifiesParsingError();
        });
      });
    });

    describe('action section  when the "approvalPolicyDisableBotComment" feature is on', () => {
      beforeEach(() => {
        uniqueId
          .mockImplementationOnce(jest.fn((prefix) => `${prefix}0`))
          .mockImplementationOnce(jest.fn((prefix) => `${prefix}1`));
      });

      afterEach(() => {
        uniqueId.mockRestore();
      });

      describe('rendering', () => {
        it.each`
          namespaceType              | policy
          ${NAMESPACE_TYPES.PROJECT} | ${APPROVAL_POLICY_DEFAULT_POLICY_WITH_BOT_MESSAGE}
        `('should render default policy for a $namespaceType', ({ namespaceType, policy }) => {
          factory({
            glFeatures: { approvalPolicyDisableBotComment: true },
            provide: { namespaceType },
          });
          expect(findPolicyEditorLayout().props('policy')).toEqual(policy);
        });

        it.each`
          namespaceType              | manifest
          ${NAMESPACE_TYPES.GROUP}   | ${DEFAULT_SCAN_RESULT_POLICY_WITH_SCOPE}
          ${NAMESPACE_TYPES.PROJECT} | ${DEFAULT_SCAN_RESULT_POLICY_WITH_BOT_MESSAGE}
        `(
          'should use the correct default policy yaml for a $namespaceType',
          ({ namespaceType, manifest }) => {
            factory({
              glFeatures: { approvalPolicyDisableBotComment: true },
              provide: { namespaceType },
            });
            expect(findPolicyEditorLayout().props('yamlEditorValue')).toBe(manifest);
          },
        );

        it('displays the action section and scan filter selector on the project-level', () => {
          factory({
            glFeatures: { approvalPolicyDisableBotComment: true },
            provide: { namespaceType: NAMESPACE_TYPES.PROJECT },
          });
          expect(findActionSection().exists()).toBe(true);
          expect(findApproverAction().exists()).toBe(false);
        });

        it('displays the approver action and the add action button on the group-level', () => {
          factory({
            glFeatures: { approvalPolicyDisableBotComment: true },
            provide: { namespaceType: NAMESPACE_TYPES.GROUP },
          });
          expect(findActionSection().exists()).toBe(false);
          expect(findApproverAction().exists()).toBe(true);
        });

        it('displays multiple action sections', () => {
          factoryWithExistingPolicy({
            glFeatures: { approvalPolicyDisableBotComment: true },
            policy: mockBotMessageScanResultObject,
          });
          expect(findAllActionSections()).toHaveLength(2);
        });
      });

      describe('add', () => {
        it('hides the scan filter selector by default, when all action types are used', () => {
          factoryWithExistingPolicy({
            glFeatures: { approvalPolicyDisableBotComment: true },
            policy: mockBotMessageScanResultObject,
          });
          expect(findScanFilterSelector().exists()).toBe(false);
        });

        it('shows the scan filter selector if there are action types not shown', async () => {
          factoryWithExistingPolicy({
            glFeatures: { approvalPolicyDisableBotComment: true },
            policy: mockBotMessageScanResultObject,
          });
          await findAllActionSections().at(0).vm.$emit('remove');
          expect(findScanFilterSelector().exists()).toBe(true);
          expect(findScanFilterSelector().props('filters')).toEqual([
            { text: 'Require Approvers', value: 'require_approval' },
          ]);
        });
      });

      describe('remove', () => {
        it('removes the initial action', async () => {
          factory({ glFeatures: { approvalPolicyDisableBotComment: true } });
          expect(findActionSection().exists()).toBe(true);
          expect(findPolicyEditorLayout().props('policy')).toHaveProperty('actions');
          await findActionSection().vm.$emit('remove');
          await findActionSection().vm.$emit('remove');
          expect(findActionSection().exists()).toBe(false);
          expect(findPolicyEditorLayout().props('policy')).not.toHaveProperty('actions');
        });

        it('removes the action approvers when the action is removed', async () => {
          factory({ glFeatures: { approvalPolicyDisableBotComment: true } });
          await findActionSection().vm.$emit(
            'changed',
            mockDefaultBranchesScanResultObject.actions[0],
          );
          await findAllActionSections().at(0).vm.$emit('remove');
          await findScanFilterSelector().vm.$emit('select', REQUIRE_APPROVAL_TYPE);
          expect(findPolicyEditorLayout().props('policy').actions).toEqual([
            { type: 'send_bot_message', enabled: true, id: 'action_1' },
            { approvals_required: 1, type: 'require_approval', id: 'action_0' },
          ]);
          expect(findActionSection().props('existingApprovers')).toEqual({});
        });
      });

      describe('update', () => {
        beforeEach(() => {
          factory({ glFeatures: { approvalPolicyDisableBotComment: true } });
        });

        it('updates policy action when edited', async () => {
          const UPDATED_ACTION = { type: 'required_approval', group_approvers_ids: [1] };
          await findActionSection().vm.$emit('changed', UPDATED_ACTION);

          expect(findActionSection().props('initAction')).toEqual(UPDATED_ACTION);
        });

        it('updates the policy approvers', async () => {
          const newApprover = ['owner'];

          await findActionSection().vm.$emit('updateApprovers', {
            ...scanResultPolicyApprovers,
            role: newApprover,
          });

          expect(findActionSection().props('existingApprovers')).toMatchObject({
            role: newApprover,
          });
        });

        it('creates an error when the action section emits one', async () => {
          await findActionSection().vm.$emit('error');
          verifiesParsingError();
        });
      });
    });
  });

  describe('yaml mode updates', () => {
    beforeEach(factory);

    it('updates the policy yaml and policy object when "update-yaml" is emitted', async () => {
      await findPolicyEditorLayout().vm.$emit('update-yaml', mockDefaultBranchesScanResultManifest);
      expect(findPolicyEditorLayout().props('yamlEditorValue')).toBe(
        mockDefaultBranchesScanResultManifest,
      );
      expect(findPolicyEditorLayout().props('policy')).toMatchObject(
        mockDefaultBranchesScanResultObject,
      );
    });

    it('disables all rule mode related components when the yaml is invalid', async () => {
      await findPolicyEditorLayout().vm.$emit('update-yaml', unsupportedManifest);

      expect(findAllDisabledComponents().at(0).props('disabled')).toBe(true);
      expect(findAllDisabledComponents().at(1).props('disabled')).toBe(true);
    });
  });

  describe('CRUD operations', () => {
    it.each`
      status                            | action                             | event              | factoryFn                    | yamlEditorValue                          | currentlyAssignedPolicyProject
      ${'to save a new policy'}         | ${SECURITY_POLICY_ACTIONS.APPEND}  | ${'save-policy'}   | ${factory}                   | ${DEFAULT_SCAN_RESULT_POLICY}            | ${newlyCreatedPolicyProject}
      ${'to update an existing policy'} | ${SECURITY_POLICY_ACTIONS.REPLACE} | ${'save-policy'}   | ${factoryWithExistingPolicy} | ${mockDefaultBranchesScanResultManifest} | ${assignedPolicyProject}
      ${'to delete an existing policy'} | ${SECURITY_POLICY_ACTIONS.REMOVE}  | ${'remove-policy'} | ${factoryWithExistingPolicy} | ${mockDefaultBranchesScanResultManifest} | ${assignedPolicyProject}
    `(
      'navigates to the new merge request when "modifyPolicy" is emitted $status',
      async ({ action, event, factoryFn, yamlEditorValue, currentlyAssignedPolicyProject }) => {
        factoryFn();

        findPolicyEditorLayout().vm.$emit(event);
        await waitForPromises();

        expect(modifyPolicy).toHaveBeenCalledWith({
          action,
          assignedPolicyProject: currentlyAssignedPolicyProject,
          name:
            action === SECURITY_POLICY_ACTIONS.APPEND
              ? fromYaml({ manifest: yamlEditorValue }).name
              : mockDefaultBranchesScanResultObject.name,
          namespacePath: defaultProjectPath,
          yamlEditorValue,
        });
        expect(visitUrl).toHaveBeenCalledWith(
          `/${currentlyAssignedPolicyProject.fullPath}/-/merge_requests/2`,
        );
      },
    );

    describe('error handling', () => {
      const createError = (cause) => ({ message: 'There was an error', cause });
      const approverCause = { field: 'approvers_ids' };
      const branchesCause = { field: 'branches' };
      const unknownCause = { field: 'unknown' };

      describe('when in rule mode', () => {
        it('passes errors with the cause of `approvers_ids` to the action section', async () => {
          const error = createError([approverCause]);
          modifyPolicy.mockRejectedValue(error);
          factory();
          await findPolicyEditorLayout().vm.$emit('save-policy');
          await waitForPromises();

          expect(findApproverAction().props('errors')).toEqual(error.cause);
          expect(wrapper.emitted('error')).toStrictEqual([['']]);
        });

        it('emits error with the cause of `branches`', async () => {
          const error = createError([branchesCause]);
          modifyPolicy.mockRejectedValue(error);
          factory();
          await findPolicyEditorLayout().vm.$emit('save-policy');
          await waitForPromises();

          expect(findApproverAction().props('errors')).toEqual([]);
          expect(wrapper.emitted('error')).toStrictEqual([[''], [error.message]]);
        });

        it('emits error with an unknown cause', async () => {
          const error = createError([unknownCause]);
          modifyPolicy.mockRejectedValue(error);
          factory();
          await findPolicyEditorLayout().vm.$emit('save-policy');
          await waitForPromises();

          expect(findApproverAction().props('errors')).toEqual([]);
          expect(wrapper.emitted('error')).toStrictEqual([[''], [error.message]]);
        });

        it('handles mixed errors', async () => {
          const error = createError([approverCause, branchesCause, unknownCause]);
          modifyPolicy.mockRejectedValue(error);
          factory();
          await findPolicyEditorLayout().vm.$emit('save-policy');
          await waitForPromises();

          expect(findApproverAction().props('errors')).toEqual([approverCause]);
          expect(wrapper.emitted('error')).toStrictEqual([[''], ['There was an error']]);
        });
      });

      describe('when in yaml mode', () => {
        it('emits errors', async () => {
          const error = createError([approverCause, branchesCause, unknownCause]);
          modifyPolicy.mockRejectedValue(error);
          factory();
          changesToYamlMode();
          await findPolicyEditorLayout().vm.$emit('save-policy');
          await waitForPromises();

          expect(findApproverAction().props('errors')).toEqual([]);
          expect(wrapper.emitted('error')).toStrictEqual([[''], [error.message]]);
        });
      });
    });
  });

  describe('errors', () => {
    it('creates an error for invalid yaml', async () => {
      factory();

      await findPolicyEditorLayout().vm.$emit('update-yaml', 'invalid manifest');

      verifiesParsingError();
    });

    it('creates an error when policy scanners are invalid', async () => {
      factoryWithExistingPolicy({ policy: { rules: [{ scanners: ['cluster_image_scanning'] }] } });

      await changesToRuleMode();
      verifiesParsingError();
    });

    it('creates an error when policy severity_levels are invalid', async () => {
      factoryWithExistingPolicy({ policy: { rules: [{ severity_levels: ['non-existent'] }] } });

      await changesToRuleMode();
      verifiesParsingError();
    });

    it('creates an error when vulnerabilities_allowed are invalid', async () => {
      factoryWithExistingPolicy({ policy: { rules: [{ vulnerabilities_allowed: 'invalid' }] } });

      await changesToRuleMode();
      verifiesParsingError();
    });

    it('creates an error when vulnerability_states are invalid', async () => {
      factoryWithExistingPolicy({ policy: { rules: [{ vulnerability_states: ['invalid'] }] } });

      await changesToRuleMode();
      verifiesParsingError();
    });

    it('creates an error when vulnerability_age is invalid', async () => {
      factoryWithExistingPolicy({
        policy: { rules: [{ vulnerability_age: { operator: 'invalid' } }] },
      });

      await changesToRuleMode();
      verifiesParsingError();
    });

    it('creates an error when vulnerability_attributes are invalid', async () => {
      factoryWithExistingPolicy({
        policy: { rules: [{ vulnerability_attributes: [{ invalid: true }] }] },
      });

      await changesToRuleMode();
      verifiesParsingError();
    });

    describe('existing approvers', () => {
      const existingPolicyWithUserId = {
        actions: [{ type: 'require_approval', approvals_required: 1, user_approvers_ids: [1] }],
      };

      const existingUserApprover = {
        user: [{ id: 1, username: 'the.one', state: 'active', type: USER_TYPE }],
      };
      const nonExistingUserApprover = {
        user: [{ id: 2, username: 'the.two', state: 'active', type: USER_TYPE }],
      };

      it.each`
        title         | policy                      | approver                   | output
        ${'does not'} | ${{}}                       | ${existingUserApprover}    | ${false}
        ${'does'}     | ${{}}                       | ${nonExistingUserApprover} | ${true}
        ${'does not'} | ${existingPolicyWithUserId} | ${existingUserApprover}    | ${false}
        ${'does'}     | ${existingPolicyWithUserId} | ${nonExistingUserApprover} | ${true}
      `(
        '$title create an error when the policy does not match existing approvers',
        async ({ policy, approver, output }) => {
          factoryWithExistingPolicy({
            policy,
            provide: {
              scanResultPolicyApprovers: approver,
            },
          });

          await changesToRuleMode();
          expect(findPolicyEditorLayout().props('hasParsingError')).toBe(output);
        },
      );
    });
  });

  describe('branches being validated', () => {
    it.each`
      status                             | value       | errorMessage
      ${'invalid branches do not exist'} | ${[]}       | ${''}
      ${'invalid branches exist'}        | ${['main']} | ${'The following branches do not exist on this development project: main. Please review all protected branches to ensure the values are accurate before updating this policy.'}
    `(
      'triggers error event with the correct content when $status',
      async ({ value, errorMessage }) => {
        const rule = { ...mockDefaultBranchesScanResultObject.rules[0], branches: ['main'] };
        getInvalidBranches.mockReturnValue(value);

        factoryWithExistingPolicy({ policy: { rules: [rule] } });

        await findPolicyEditorLayout().vm.$emit('update-editor-mode', EDITOR_MODE_RULE);
        await waitForPromises();
        const errors = wrapper.emitted('error');

        expect(errors[errors.length - 1]).toEqual([errorMessage]);
      },
    );

    it('does not query protected branches when namespaceType is other than project', async () => {
      factoryWithExistingPolicy({ provide: { namespaceType: NAMESPACE_TYPES.GROUP } });

      await findPolicyEditorLayout().vm.$emit('update-editor-mode', EDITOR_MODE_RULE);
      await waitForPromises();

      expect(getInvalidBranches).not.toHaveBeenCalled();
    });
  });

  describe('settings section', () => {
    describe('settings', () => {
      const defaultProjectApprovalConfiguration = {
        [PREVENT_PUSHING_AND_FORCE_PUSHING]: true,
        [BLOCK_BRANCH_MODIFICATION]: true,
      };

      beforeEach(() => {
        factory();
      });

      it('displays setting section', () => {
        expect(findSettingsSection().exists()).toBe(true);
        expect(findSettingsSection().props('settings')).toEqual(
          defaultProjectApprovalConfiguration,
        );
      });

      it('shows default settings for non-merge request rules', async () => {
        await findAllRuleSections().at(0).vm.$emit('changed', { type: 'scan_finding' });
        expect(findSettingsSection().exists()).toBe(true);
        expect(findSettingsSection().props('settings')).toEqual(
          defaultProjectApprovalConfiguration,
        );
      });

      it('shows the policy for merge request rule in addition to the default settings', async () => {
        await findAllRuleSections().at(0).vm.$emit('changed', { type: 'any_merge_request' });
        expect(findSettingsSection().props('settings')).toEqual({
          ...defaultProjectApprovalConfiguration,
          ...mergeRequestConfiguration,
        });
      });

      it('updates the policy for merge request rule', async () => {
        findAllRuleSections().at(0).vm.$emit('changed', { type: 'any_merge_request' });
        await findSettingsSection().vm.$emit('changed', {
          [PREVENT_APPROVAL_BY_AUTHOR]: false,
        });
        expect(findSettingsSection().props('settings')).toEqual({
          ...protectedBranchesConfiguration,
          ...pushingBranchesConfiguration,
          ...mergeRequestConfiguration,
          [PREVENT_APPROVAL_BY_AUTHOR]: false,
        });
      });

      it('updates the policy when a change is emitted for pushingBranchesConfiguration', async () => {
        await findSettingsSection().vm.$emit('changed', {
          [PREVENT_PUSHING_AND_FORCE_PUSHING]: false,
        });
        expect(findPolicyEditorLayout().props('yamlEditorValue')).toContain(
          `${PREVENT_PUSHING_AND_FORCE_PUSHING}: false`,
        );
      });

      it('updates the policy when a change is emitted for blockBranchModification', async () => {
        await findSettingsSection().vm.$emit('changed', {
          [BLOCK_BRANCH_MODIFICATION]: false,
        });
        expect(findPolicyEditorLayout().props('yamlEditorValue')).toContain(
          `${BLOCK_BRANCH_MODIFICATION}: false`,
        );
      });
    });

    describe('empty policy alert', () => {
      const policy = { approval_settings: { [BLOCK_BRANCH_MODIFICATION]: true } };
      describe('when there are actions and settings', () => {
        beforeEach(() => {
          factoryWithExistingPolicy({ policy });
        });

        it('does not display the alert', () => {
          expect(findEmptyActionsAlert().exists()).toBe(false);
        });

        it('does not disable the save button', () => {
          expect(findPolicyEditorLayout().props('disableUpdate')).toBe(false);
        });
      });

      describe('when there are actions and no settings', () => {
        beforeEach(() => {
          factoryWithExistingPolicy();
        });

        it('does not display the alert', () => {
          expect(findEmptyActionsAlert().exists()).toBe(false);
        });

        it('does not disable the save button', () => {
          expect(findPolicyEditorLayout().props('disableUpdate')).toBe(false);
        });
      });

      describe('when there are settings and no actions', () => {
        beforeEach(() => {
          factoryWithExistingPolicy({ hasActions: false, policy });
        });

        it('displays the alert', () => {
          expect(findEmptyActionsAlert().exists()).toBe(true);
          expect(findEmptyActionsAlert().props('variant')).toBe('warning');
        });

        it('does not disable the save button', () => {
          expect(findPolicyEditorLayout().props('disableUpdate')).toBe(false);
        });
      });

      describe('displays the danger alert when there are no actions and no settings', () => {
        beforeEach(() => {
          factoryWithExistingPolicy({
            policy: { actions: [], approval_settings: { [BLOCK_BRANCH_MODIFICATION]: false } },
          });
        });

        it('displays the danger alert', () => {
          expect(findEmptyActionsAlert().exists()).toBe(true);
          expect(findEmptyActionsAlert().props('variant')).toBe('danger');
        });

        it('disabled the update button', () => {
          expect(findPolicyEditorLayout().props('disableUpdate')).toBe(true);
        });
      });

      describe('does not display the danger alert when the policy is invalid', () => {
        beforeEach(() => {
          factoryWithExistingPolicy({
            policy: { approval_settings: { invalid_setting: true } },
          });
        });

        it('displays the danger alert', () => {
          expect(findEmptyActionsAlert().exists()).toBe(false);
        });

        it('disabled the update button', () => {
          expect(findPolicyEditorLayout().props('disableUpdate')).toBe(false);
        });
      });
    });
  });
});

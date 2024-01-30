export { createPolicyObject, fromYaml } from './from_yaml';
export { policyToYaml } from './to_yaml';
export * from './rules';
export {
  approversOutOfSync,
  APPROVER_TYPE_DICT,
  APPROVER_TYPE_LIST_ITEMS,
  buildApprovalAction,
} from './actions';
export * from './settings';
export * from './vulnerability_states';
export * from './filters';

export const DEFAULT_PROJECT_SCAN_RESULT_POLICY = `type: approval_policy
name: ''
description: ''
enabled: true
rules:
  - type: ''
actions:
  - type: require_approval
    approvals_required: 1
approval_settings:
  prevent_pushing_and_force_pushing: true
`;

export const DEFAULT_GROUP_SCAN_RESULT_POLICY = `type: approval_policy
name: ''
description: ''
enabled: true
policy_scope:
  compliance_frameworks: []
rules:
  - type: ''
actions:
  - type: require_approval
    approvals_required: 1
approval_settings:
  prevent_pushing_and_force_pushing: true
`;

export { createPolicyObject, fromYaml } from './from_yaml';
export { toYaml } from './to_yaml';
export * from './rules';
export { approversOutOfSync, APPROVER_TYPE_DICT, APPROVER_TYPE_LIST_ITEMS } from './actions';
export * from './settings';
export * from './vulnerability_states';
export * from './filters';

export const DEFAULT_PROJECT_SCAN_RESULT_POLICY = `type: scan_result_policy
name: ''
description: ''
enabled: true
rules:
  - type: ''
actions:
  - type: require_approval
    approvals_required: 1
`;

export const DEFAULT_GROUP_SCAN_RESULT_POLICY = `type: scan_result_policy
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
`;

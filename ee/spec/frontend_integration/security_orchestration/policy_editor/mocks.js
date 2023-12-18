import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

export const DEFAULT_PROVIDE = {
  disableScanPolicyUpdate: false,
  disableSecurityPolicyProject: false,
  policyEditorEmptyStateSvgPath: 'path/to/svg',
  namespaceId: 1,
  namespacePath: 'path/to/project',
  namespaceType: NAMESPACE_TYPES.PROJECT,
  scanPolicyDocumentationPath: 'path/to/policy-docs',
  scanResultPolicyApprovers: {
    user: [{ id: 1, username: 'the.one', state: 'active' }],
    group: [],
    role: [],
  },
  assignedPolicyProject: {},
  createAgentHelpPath: 'path/to/agent-docs',
  globalGroupApproversEnabled: false,
  maxActiveScanExecutionPoliciesReached: false,
  maxActiveScanResultPoliciesReached: false,
  maxScanExecutionPoliciesAllowed: 5,
  maxScanResultPoliciesAllowed: 5,
  policiesPath: 'path/to/policies',
  policyType: 'scan_execution',
  roleApproverTypes: [],
  rootNamespacePath: 'path/to/root',
  parsedSoftwareLicenses: [],
  timezones: [],
};

export const mockSecurityScanResultManifest = `type: scan_result_policy
name: ''
description: ''
enabled: true
rules:
  - type: scan_finding
    scanners: []
    vulnerabilities_allowed: 0
    severity_levels: []
    vulnerability_states: []
    branch_type: protected
actions:
  - type: require_approval
    approvals_required: 1
`;

export const mockLicenseScanResultManifest = `type: scan_result_policy
name: ''
description: ''
enabled: true
rules:
  - type: license_finding
    match_on_inclusion: true
    license_types: []
    license_states: []
    branch_type: protected
actions:
  - type: require_approval
    approvals_required: 1
`;

export const mockAnyMergeRequestScanResultManifest = `type: scan_result_policy
name: ''
description: ''
enabled: true
rules:
  - type: any_merge_request
    branch_type: protected
    commits: any
actions:
  - type: require_approval
    approvals_required: 1
approval_settings:
  prevent_approval_by_author: true
  prevent_approval_by_commit_author: true
  remove_approvals_with_new_commit: true
  require_password_to_approve: false
`;

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
approval_settings: {}
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
approval_settings: {}
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

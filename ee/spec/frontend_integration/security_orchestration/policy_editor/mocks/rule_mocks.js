export const mockSecurityApprovalManifest = `type: approval_policy
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
approval_settings:
  prevent_pushing_and_force_pushing: true
`;

export const mockLicenseApprovalManifest = `type: approval_policy
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
approval_settings:
  prevent_pushing_and_force_pushing: true
`;

export const mockAnyMergeRequestApprovalManifest = `type: approval_policy
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
  prevent_pushing_and_force_pushing: true
  prevent_approval_by_author: true
  prevent_approval_by_commit_author: true
  remove_approvals_with_new_commit: true
  require_password_to_approve: false
`;

export const mockPipelineScanExecutionManifest = `type: scan_execution_policy
name: ''
description: ''
enabled: true
rules:
  - type: pipeline
    branches:
      - '*'
actions:
  - scan: secret_detection
`;

export const mockScheduleScanExecutionManifest = `type: scan_execution_policy
name: ''
description: ''
enabled: true
rules:
  - type: schedule
    branches: []
    cadence: 0 0 * * *
actions:
  - scan: secret_detection
`;

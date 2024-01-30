import { GROUP_TYPE, USER_TYPE } from 'ee/security_orchestration/constants';

export const USER = {
  id: 2,
  name: 'Name 1',
  username: 'name.1',
  avatarUrl: 'https://www.gravatar.com/avatar/1234',
  type: USER_TYPE,
  __typename: 'UserCore',
};

export const GROUP = {
  avatarUrl: null,
  id: 1,
  fullName: 'Name 1',
  fullPath: 'path/to/name-1',
  type: GROUP_TYPE,
};

export const mockRoleApproversApprovalManifest = `type: approval_policy
name: ''
description: ''
enabled: true
rules:
  - type: ''
actions:
  - type: require_approval
    approvals_required: 2
    role_approvers:
      - developer
approval_settings:
  prevent_pushing_and_force_pushing: true
`;

export const mockUserApproversApprovalManifest = `type: approval_policy
name: ''
description: ''
enabled: true
rules:
  - type: ''
actions:
  - type: require_approval
    approvals_required: 2
    user_approvers_ids:
      - ${USER.id}
approval_settings:
  prevent_pushing_and_force_pushing: true
`;

export const mockGroupApproversApprovalManifest = `type: approval_policy
name: ''
description: ''
enabled: true
rules:
  - type: ''
actions:
  - type: require_approval
    approvals_required: 2
    group_approvers_ids:
      - ${GROUP.id}
approval_settings:
  prevent_pushing_and_force_pushing: true
`;

const mockScanExecutionManifest = `type: scan_execution_policy
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

export const mockActionsVariablesScanExecutionManifest = `type: scan_execution_policy
name: ''
description: ''
enabled: true
rules:
  - type: pipeline
    branches:
      - '*'
actions:
  - scan: secret_detection
    variables:
      '': ''
`;

export const mockDastActionScanExecutionManifest = `type: scan_execution_policy
name: ''
description: ''
enabled: true
rules:
  - type: pipeline
    branches:
      - '*'
actions:
  - scan: dast
    site_profile: ''
    scanner_profile: ''
`;

export const createScanActionScanExecutionManifest = (scanType) =>
  mockScanExecutionManifest.replace('scan: secret_detection', `scan: ${scanType}`);

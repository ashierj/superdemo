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

export const mockRoleApproversScanResultManifest = `type: scan_result_policy
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
`;

export const mockUserApproversScanResultManifest = `type: scan_result_policy
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
`;

export const mockGroupApproversScanResultManifest = `type: scan_result_policy
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

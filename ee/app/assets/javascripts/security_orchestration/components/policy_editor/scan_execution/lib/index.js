export { createPolicyObject, fromYaml } from './from_yaml';
export { toYaml } from './to_yaml';
export * from './rules';
export * from './cron';
export * from './actions';

export const DEFAULT_PROJECT_SCAN_EXECUTION_POLICY = `type: scan_execution_policy
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

export const DEFAULT_GROUP_SCAN_EXECUTION_POLICY = `type: scan_execution_policy
name: ''
description: ''
enabled: true
policy_scope:
  compliance_frameworks: []
rules:
  - type: pipeline
    branches:
      - '*'
actions:
  - scan: secret_detection
`;

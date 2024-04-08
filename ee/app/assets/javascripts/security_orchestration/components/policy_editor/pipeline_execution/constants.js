import { s__ } from '~/locale';

export const DEFAULT_PIPELINE_EXECUTION_POLICY = `type: pipeline_execution_policy
name: ''
description: ''
enabled: true
rules:
  - foo: bar
actions:
  - foo: bar
`;

export const ADD_CONDITION_LABEL = s__('ScanExecutionPolicy|Add condition');
export const CONDITIONS_LABEL = s__('ScanExecutionPolicy|Conditions');

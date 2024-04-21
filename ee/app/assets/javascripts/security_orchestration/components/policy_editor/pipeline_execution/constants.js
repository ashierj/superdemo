import { s__ } from '~/locale';

export const DEFAULT_PIPELINE_EXECUTION_POLICY = `type: pipeline_execution_policy
name: ''
description: ''
enabled: true
override_project_ci: false
content:
  include:
    project: ''
`;

export const CONDITIONS_LABEL = s__('ScanExecutionPolicy|Conditions');

import { fromYaml } from 'ee/security_orchestration/components/policy_editor/pipeline_execution/utils';

/**
 * Naming convention for mocks:
 * mock policy yaml => name ends in `Manifest`
 * mock parsed yaml => name ends in `Object`
 * mock policy for list/drawer => name ends in `PipelinePolicy`
 *
 * If you have the same policy in multiple forms (e.g. mock yaml and mock parsed yaml that should
 * match), please name them similarly (e.g. fooBarManifest and fooBarObject)
 * and keep them near each other.
 */

export const customYaml = `variable: true
`;

export const customYamlObject = { variable: true };

export const configFileManifest = `name: "Ci config file"
description: "triggers all protected branches except main"
enabled: true
override_project_ci: false
content:
  include:
    project: GitLab.org/GitLab
    file: .pipeline-execution.yml
`;

export const configFileObject = fromYaml({ manifest: configFileManifest });

export const nonBooleanOverrideTypeManifest = `name: "Ci config file"
description: "triggers all protected branches except main"
enabled: true
override_project_ci: this_is_wrong
content:
  include:
    project: GitLab.org/GitLab
    file: .pipeline-execution.yml
`;

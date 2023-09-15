import { __, s__ } from '~/locale';

// Checks and proper values sourced from:
// https://gitlab.com/gitlab-org/gitlab/-/blob/ea5e2706045c51ea2a2e408e39093da0aca3eec7/doc/api/graphql/reference/index.md#L25792
const PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR = 'PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR';
const PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS = 'PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS';
const AT_LEAST_TWO_APPROVALS = 'AT_LEAST_TWO_APPROVALS';

export const FAIL_STATUS = 'FAIL';
export const NO_STANDARDS_ADHERENCES_FOUND = s__(
  'ComplianceStandardsAdherence|No projects with standards adherence checks found',
);

export const STANDARDS_ADHERENCE_CHECK_LABELS = {
  [PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR]: s__(
    'ComplianceStandardsAdherence|Prevent authors as approvers',
  ),
  [PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS]: s__(
    'ComplianceStandardsAdherence|Prevent committers as approvers',
  ),
  [AT_LEAST_TWO_APPROVALS]: s__('ComplianceStandardsAdherence|At least two approvals'),
};

export const STANDARDS_ADHERENCE_CHECK_DESCRIPTIONS = {
  [PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR]: s__(
    'ComplianceStandardsAdherence|Have a valid rule that prevents author approved merge requests',
  ),
  [PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS]: s__(
    'ComplianceStandardsAdherence|Have a valid rule that prevents merge requests approved by committers',
  ),
  [AT_LEAST_TWO_APPROVALS]: s__(
    'ComplianceStandardsAdherence|Have a valid rule that requires any merge request to have more than two approvals',
  ),
};

export const STANDARDS_ADHERENCE_CHECK_FAILURE_REASONS = {
  [PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR]: s__(
    'ComplianceStandardsAdherence|No rule is configured to prevent author approved merge requests.',
  ),
  [PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS]: s__(
    'ComplianceStandardsAdherence|No rule configured to prevent merge requests approved by committers.',
  ),
  [AT_LEAST_TWO_APPROVALS]: s__(
    'ComplianceStandardsAdherence|No rule is configured to require two approvals.',
  ),
};

export const STANDARDS_ADHERENCE_CHECK_MR_FIX_TITLE = s__(
  'ComplianceStandardsAdherence|The following features help satisfy this requirement.',
);

export const STANDARDS_ADHERENCE_CHECK_MR_FIX_FEATURES = [
  {
    title: s__('ComplianceStandardsAdherence|Merge request approval rules'),
    description: s__(
      "ComplianceStandardsAdherence|Update approval settings in the project's merge request settings to satisfy this requirement.",
    ),
  },
];
const GITLAB = 'GITLAB';

export const STANDARDS_ADHERENCE_STANARD_LABELS = {
  [GITLAB]: __('GitLab'),
};

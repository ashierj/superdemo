import { s__ } from '~/locale';

export const PROJECTS_WITH_FRAMEWORK = 'projects_with_framework';
export const ALL_PROJECTS_IN_GROUP = 'all_projects_in_group';
export const SPECIFIC_PROJECTS = 'specific_projects';

export const PROJECT_SCOPE_TYPE_LISTBOX_TEXTS = {
  [PROJECTS_WITH_FRAMEWORK]: s__('SecurityOrchestration|projects with compliance frameworks'),
  [ALL_PROJECTS_IN_GROUP]: s__('SecurityOrchestration|all projects in this group'),
  [SPECIFIC_PROJECTS]: s__('SecurityOrchestration|specific projects'),
};

export const PROJECT_SCOPE_TYPE_LISTBOX = Object.entries(PROJECT_SCOPE_TYPE_LISTBOX_TEXTS).map(
  ([value, text]) => ({
    value,
    text,
  }),
);

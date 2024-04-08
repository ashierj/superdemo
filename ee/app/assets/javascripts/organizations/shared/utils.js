import {
  renderProjectDeleteSuccessToast as renderProjectDeleteSuccessToastCE,
  deleteProjectParams as deleteProjectParamsCE,
} from '~/organizations/shared/utils';
import toast from '~/vue_shared/plugins/global_toast';
import { sprintf, __ } from '~/locale';

// Exports override for EE
// eslint-disable-next-line import/export
export * from '~/organizations/shared/utils';

// Exports override for EE
// eslint-disable-next-line import/export
export const renderProjectDeleteSuccessToast = (project) => {
  // If delayed deletion is disabled or the project is already marked for deletion, use the CE toast
  if (!project.isAdjournedDeletionEnabled || project.markedForDeletionOn) {
    renderProjectDeleteSuccessToastCE(project);
    return;
  }

  toast(
    sprintf(__("Project '%{name}' will be deleted on %{date}."), {
      name: project.name,
      date: project.permanentDeletionDate,
    }),
  );
};

// Exports override for EE
// eslint-disable-next-line import/export
export const deleteProjectParams = (project) => {
  // If delayed deletion is disabled or the project is not yet marked for deletion, use the CE params
  if (!project.isAdjournedDeletionEnabled || !project.markedForDeletionOn) {
    return deleteProjectParamsCE();
  }

  return { permanently_remove: true, full_path: project.fullPath };
};

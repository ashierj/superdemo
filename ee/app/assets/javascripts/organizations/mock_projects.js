// This is temporary mock data that will be removed when completing the following:
// https://gitlab.com/gitlab-org/gitlab/-/issues/420777
// https://gitlab.com/gitlab-org/gitlab/-/issues/421441

import { organizationProjects as organizationProjectsCE } from '~/organizations/mock_projects';

export const organizationProjects = organizationProjectsCE.map((project, index, array) => {
  return {
    ...project,
    markedForDeletionOn: index === array.length - 1 ? '2024-01-01' : null,
  };
});

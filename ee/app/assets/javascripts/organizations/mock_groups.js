// This is temporary mock data that will be removed when completing the following:
// https://gitlab.com/gitlab-org/gitlab/-/issues/420777
// https://gitlab.com/gitlab-org/gitlab/-/issues/421441

import { organizationGroups as organizationGroupsCE } from '~/organizations/mock_groups';

export const organizationGroups = organizationGroupsCE.map((group, index, array) => {
  return {
    ...group,
    markedForDeletionOn: index === array.length - 1 ? '2024-01-01' : null,
    isAdjournedDeletionEnabled: true,
    permanentDeletionDate: index === array.length - 1 ? '2024-01-01' : null,
  };
});

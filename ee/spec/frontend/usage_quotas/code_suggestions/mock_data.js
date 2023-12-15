import { ADD_ON_CODE_SUGGESTIONS } from 'ee/usage_quotas/code_suggestions/constants';

export const noAssignedAddonData = {
  data: {
    addOnPurchase: {
      id: 'gid://gitlab/GitlabSubscriptions::AddOnPurchase/3',
      name: ADD_ON_CODE_SUGGESTIONS,
      assignedQuantity: 0,
      purchasedQuantity: 20,
      __typename: 'AddOnPurchase',
    },
  },
};

export const noPurchasedAddonData = {
  data: {
    addOnPurchase: null,
  },
};

export const purchasedAddonFuzzyData = {
  data: {
    addOnPurchase: {
      id: 'gid://gitlab/GitlabSubscriptions::AddOnPurchase/3',
      name: ADD_ON_CODE_SUGGESTIONS,
      assignedQuantity: 0,
      purchasedQuantity: undefined,
      __typename: 'AddOnPurchase',
    },
  },
};

export const mockNoAddOnEligibleUsers = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/176',
      addOnEligibleUsers: {
        nodes: [],
      },
    },
  },
};

export const mockUserWithAddOnAssignment = {
  id: 'gid://gitlab/User/1',
  username: 'userone',
  name: 'User One',
  publicEmail: null,
  avatarUrl: 'path/to/img_userone',
  webUrl: 'path/to/userone',
  lastActivityOn: '2023-08-25',
  addOnAssignments: {
    nodes: [{ addOnPurchase: { name: 'CODE_SUGGESTIONS' } }],
    __typename: 'UserAddOnAssignmentConnection',
  },
  __typename: 'AddOnUser',
};

export const mockUserWithNoAddOnAssignment = {
  id: 'gid://gitlab/User/2',
  username: 'usertwo',
  name: 'User Two',
  publicEmail: null,
  avatarUrl: 'path/to/img_usertwo',
  webUrl: 'path/to/usertwo',
  lastActivityOn: '2023-08-22',
  addOnAssignments: { nodes: [], __typename: 'UserAddOnAssignmentConnection' },
  __typename: 'AddOnUser',
};

export const eligibleUsers = [mockUserWithAddOnAssignment, mockUserWithNoAddOnAssignment];

const pageInfo = {
  startCursor: 'start-cursor',
  endCursor: 'end-cursor',
  __typename: 'PageInfo',
};

export const pageInfoWithNoPages = {
  hasNextPage: false,
  hasPreviousPage: false,
  ...pageInfo,
};

export const pageInfoWithMorePages = {
  hasNextPage: true,
  hasPreviousPage: true,
  ...pageInfo,
};

export const mockAddOnEligibleUsers = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/1',
      addOnEligibleUsers: {
        nodes: eligibleUsers,
        pageInfo: pageInfoWithNoPages,
        __typename: 'AddOnUserConnection',
      },
      __typename: 'Namespace',
    },
  },
};

export const mockPaginatedAddOnEligibleUsers = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/1',
      addOnEligibleUsers: {
        nodes: eligibleUsers,
        pageInfo: pageInfoWithMorePages,
      },
    },
  },
};

export const mockNoProjects = {
  data: {
    group: {
      projects: {
        nodes: [],
        __typename: 'ProjectConnection',
      },
      __typename: 'Group',
    },
  },
};

export const mockProjects = {
  data: {
    group: {
      projects: {
        nodes: [
          {
            id: 'gid://gitlab/Project/20',
            name: 'A Project',
            __typename: 'Project',
          },
          {
            id: 'gid://gitlab/Project/19',
            name: 'Another Project',
            __typename: 'Project',
          },
        ],
        __typename: 'ProjectConnection',
      },
      __typename: 'Group',
    },
  },
};

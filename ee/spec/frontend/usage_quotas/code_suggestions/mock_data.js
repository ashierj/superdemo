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
      purchasedQuantity: null,
      __typename: 'AddOnPurchase',
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
  maxRole: null,
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
  maxRole: null,
  addOnAssignments: { nodes: [], __typename: 'UserAddOnAssignmentConnection' },
  __typename: 'AddOnUser',
};

export const eligibleUsers = [mockUserWithAddOnAssignment, mockUserWithNoAddOnAssignment];
export const eligibleUsersWithMaxRole = eligibleUsers.map((user) => ({
  ...user,
  maxRole: 'developer',
}));

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

export const mockNoGroups = {
  data: {
    group: {
      id: 'gid://gitlab/Group/95',
      name: 'Code Suggestions Group',
      fullName: 'Code Suggestions Group',
      fullPath: 'code-suggestions-group',
      __typename: 'Group',
      descendantGroups: {
        nodes: [],
        pageInfo: {},
        __typename: 'GroupConnection',
      },
    },
  },
};

export const mockGroups = {
  data: {
    group: {
      id: 'gid://gitlab/Group/95',
      name: 'Code Suggestions Group',
      fullName: 'Code Suggestions Group',
      fullPath: 'code-suggestions-group',
      __typename: 'Group',
      descendantGroups: {
        nodes: [
          {
            id: 'gid://gitlab/Group/99',
            name: 'Code Suggestions Subgroup',
            fullName: 'Code Suggestions Group / Code Suggestions Subgroup',
            fullPath: 'code-suggestions-group/code-suggestions-subgroup',
            __typename: 'Group',
          },
        ],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
          __typename: 'PageInfo',
        },
        __typename: 'GroupConnection',
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

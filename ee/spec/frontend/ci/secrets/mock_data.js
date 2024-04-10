export const mockProjectEnvironments = {
  data: {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/20',
      environments: {
        __typename: 'EnvironmentConnection',
        nodes: [
          {
            __typename: 'Environment',
            id: 'gid://gitlab/Environment/56',
            name: 'project_env_development',
          },
          {
            __typename: 'Environment',
            id: 'gid://gitlab/Environment/55',
            name: 'project_env_production',
          },
          {
            __typename: 'Environment',
            id: 'gid://gitlab/Environment/57',
            name: 'project_env_staging',
          },
        ],
      },
    },
  },
};

export const mockGroupEnvironments = {
  data: {
    group: {
      __typename: 'Group',
      id: 'gid://gitlab/Group/96',
      environmentScopes: {
        __typename: 'CiGroupEnvironmentScopeConnection',
        nodes: [
          {
            __typename: 'CiGroupEnvironmentScope',
            name: 'group_env_development',
          },
          {
            __typename: 'CiGroupEnvironmentScope',
            name: 'group_env_production',
          },
          {
            __typename: 'CiGroupEnvironmentScope',
            name: 'group_env_staging',
          },
        ],
      },
    },
  },
};

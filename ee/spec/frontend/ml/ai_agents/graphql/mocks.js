export const createAiAgentsResponses = {
  success: {
    data: {
      aiAgentCreate: {
        agent: {
          id: 'gid://gitlab/Ai::Agent/1',
          _links: {
            showPath: '/some/project/-/ml/agents/1',
          },
        },
        errors: [],
      },
    },
  },
  validationFailure: {
    data: {
      aiAgentCreate: {
        agent: null,
        errors: ['Name is invalid', "Name can't be blank"],
      },
    },
  },
};

export const listAiAgentsResponses = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      aiAgents: {
        nodes: [
          {
            id: 'gid://gitlab/Ai::Agent/1',
            name: 'agent-1',
            versions: [
              {
                id: 'gid://gitlab/Ai::AgentVersion/1',
                prompt: 'example prompt',
                model: 'default',
              },
            ],
            _links: {
              showPath: '/namespace/projects/-/ml/agents/1',
            },
          },
        ],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: 'eyJpZCI6IjEwIn0',
          endCursor: 'eyJpZCI6IjEifQ',
          __typename: 'PageInfo',
        },
      },
    },
  },
};

export const listAiAgentsEmptyResponses = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      aiAgents: {
        nodes: [],
      },
    },
  },
};

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

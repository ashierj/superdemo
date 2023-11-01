const mergeAsObject = (existing = {}, incoming) => {
  return {
    ...existing,
    ...incoming,
  };
};

export default {
  typePolicies: {
    Project: {
      fields: {
        ciCdSettings: {
          merge: mergeAsObject,
        },
        ciJobTokenScope: {
          merge: mergeAsObject,
        },
      },
    },
  },
};

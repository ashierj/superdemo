import getGroupSecretsQuery from './queries/client/get_group_secrets.query.graphql';
import getProjectSecretsQuery from './queries/client/get_project_secrets.query.graphql';

export const cacheConfig = {
  typePolicies: {
    Group: {
      merge(existing = {}, incoming, { isReference }) {
        if (isReference(incoming)) {
          return existing;
        }
        return { ...existing, ...incoming };
      },
    },
    Project: {
      merge(existing = {}, incoming, { isReference }) {
        if (isReference(incoming)) {
          return existing;
        }
        return { ...existing, ...incoming };
      },
    },
  },
};

// client-only field pagination
// return a slice of the cached data according to offset and limit
const clientSidePaginate = (sourceData, offset, limit) => ({
  ...sourceData,
  nodes: sourceData.nodes.slice(offset, offset + limit),
});

export const resolvers = {
  Group: {
    secrets({ fullPath }, { offset, limit }, { cache }) {
      const sourceData = cache.readQuery({
        query: getGroupSecretsQuery,
        variables: { fullPath },
      }).group.secrets;

      return clientSidePaginate(sourceData, offset, limit);
    },
  },
  Project: {
    secrets({ fullPath }, { offset, limit }, { cache }) {
      const sourceData = cache.readQuery({
        query: getProjectSecretsQuery,
        variables: { fullPath },
      }).project.secrets;

      return clientSidePaginate(sourceData, offset, limit);
    },
  },
};

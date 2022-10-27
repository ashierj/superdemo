import produce from 'immer';
import createDefaultClient from '~/lib/graphql';
import getIssuesQuery from 'ee_else_ce/issues/list/queries/get_issues.query.graphql';

const resolvers = {
  Mutation: {
    reorderIssues: (_, { oldIndex, newIndex, namespace, serializedVariables }, { cache }) => {
      const variables = JSON.parse(serializedVariables);
      const sourceData = cache.readQuery({ query: getIssuesQuery, variables });

      const data = produce(sourceData, (draftData) => {
        const issues = draftData[namespace].issues.nodes.slice();
        const issueToMove = issues[oldIndex];
        issues.splice(oldIndex, 1);
        issues.splice(newIndex, 0, issueToMove);

        draftData[namespace].issues.nodes = issues;
      });

      cache.writeQuery({ query: getIssuesQuery, variables, data });
    },
  },
};

export const gqlClient = createDefaultClient(resolvers);

import { concatPagination } from '@apollo/client/utilities';
import createDefaultClient from '~/lib/graphql';

export const defaultClient = createDefaultClient(
  {},
  {
    cacheConfig: {
      typePolicies: {
        Group: {
          fields: {
            epics: {
              keyArgs: [
                'search',
                'sort',
                'labelName',
                'milestoneTitle',
                'state',
                'not',
                'authorUsername',
                'iid',
                'myReactionEmoji',
                'confidential',
                'timeframe',
                'includeDescendantGroups',
              ],
            },
          },
        },
        EpicConnection: {
          fields: {
            nodes: concatPagination(),
          },
        },
      },
    },
  },
);

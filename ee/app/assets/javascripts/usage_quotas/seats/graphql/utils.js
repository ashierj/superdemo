import produce from 'immer';
import getSubscriptionPlanQuery from 'ee/fulfillment/shared_queries/subscription_plan.query.graphql';

const PLAN_TYPE = 'Plan';
const SUBSCRIPTION_TYPE = 'Subscription';

export const writeDataToApolloCache = (apolloProvider, { code = '' } = {}) => {
  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: getSubscriptionPlanQuery,
    data: {
      subscription: {
        __typename: SUBSCRIPTION_TYPE,
        plan: {
          __typename: PLAN_TYPE,
          code,
        },
      },
    },
  });
  return apolloProvider;
};

export const updateSubscriptionPlanApolloCache = (apolloProvider, { code = '' } = {}) => {
  const sourceData = apolloProvider.clients.defaultClient.cache.readQuery({
    query: getSubscriptionPlanQuery,
  });

  if (!sourceData) {
    return;
  }

  const data = produce(sourceData, (draftState) => {
    draftState.subscription = {
      ...draftState.subscription,
      plan: {
        __typename: PLAN_TYPE,
        code,
      },
    };
  });

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: getSubscriptionPlanQuery,
    data,
  });
};

import produce from 'immer';
import { STEP_TYPE } from 'ee/subscriptions/buy_addons_shared/constants';
import activeStepQuery from './queries/active_step.query.graphql';
import stepListQuery from './queries/step_list.query.graphql';
import furthestAccessedStepQuery from './queries/furthest_accessed_step.query.graphql';

function updateActiveStep(_, { id }, { cache }) {
  const sourceData = cache.readQuery({ query: activeStepQuery });
  const { stepList } = cache.readQuery({ query: stepListQuery });
  const activeStep = stepList.find((step) => step.id === id);

  const data = produce(sourceData, (draftData) => {
    draftData.activeStep = {
      __typename: STEP_TYPE,
      id: activeStep.id,
    };
  });

  return cache.writeQuery({ query: activeStepQuery, data });
}

function getFurthestAccessedStep(activeStepIndex, stepList, currentFurthest) {
  const currentFurthestIndex = stepList.findIndex(
    (step) => step.id === currentFurthest.furthestAccessedStep.id,
  );

  if (currentFurthestIndex > activeStepIndex) {
    return stepList[currentFurthestIndex];
  }

  return stepList[activeStepIndex];
}

function activateNextStep(parent, _, { cache }) {
  const sourceData = cache.readQuery({ query: activeStepQuery });
  const { stepList } = cache.readQuery({ query: stepListQuery });
  const currentIndex = stepList.findIndex((step) => step.id === sourceData.activeStep.id);
  const newIndex = currentIndex + 1;
  const activeStep = stepList[newIndex];

  if (gon.features?.keyContactsManagementV2) {
    const currentFurthest = cache.readQuery({ query: furthestAccessedStepQuery });
    const furthestAccessedStep = getFurthestAccessedStep(newIndex, stepList, currentFurthest);

    const data = produce(sourceData, (draftData) => {
      draftData.furthestAccessedStep = {
        __typename: STEP_TYPE,
        id: furthestAccessedStep.id,
      };
    });

    cache.writeQuery({ query: furthestAccessedStepQuery, data });
  }

  const data = produce(sourceData, (draftData) => {
    draftData.activeStep = {
      __typename: STEP_TYPE,
      id: activeStep.id,
    };
  });

  return cache.writeQuery({ query: activeStepQuery, data });
}

export default {
  Mutation: {
    updateActiveStep,
    activateNextStep,
  },
};

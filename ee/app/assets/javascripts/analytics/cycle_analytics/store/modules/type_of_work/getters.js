import { getTasksByTypeData } from '../../../utils';

export const selectedTasksByTypeFilters = (state = {}, _, rootState = {}) => {
  const { selectedLabelIds = [], subject } = state;
  const {
    currentGroup,
    selectedProjectIds = [],
    createdAfter = null,
    createdBefore = null,
  } = rootState;
  return {
    currentGroup,
    selectedProjectIds,
    createdAfter,
    createdBefore,
    selectedLabelIds,
    subject,
  };
};

export const tasksByTypeChartData = ({ data = [] } = {}, _, rootState = {}) => {
  const { createdAfter = null, createdBefore = null } = rootState;
  return data.length
    ? getTasksByTypeData({ data, createdAfter, createdBefore })
    : { groupBy: [], data: [] };
};

export const topRankedLabelsIds = (state) => {
  const { topRankedLabels } = state;
  return topRankedLabels.map(({ id }) => id);
};

export const selectedLabelIds = (_state, getters, _, rootGetters) =>
  rootGetters.selectedLabelIds.length ? rootGetters.selectedLabelIds : getters.topRankedLabelsIds;

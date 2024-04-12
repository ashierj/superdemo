import { createAlert } from '~/alert';
import { s__ } from '~/locale';

import { ROADMAP_PAGE_SIZE } from '../constants';
import epicChildEpics from '../queries/epic_child_epics.query.graphql';
import groupEpics from '../queries/group_epics.query.graphql';
import groupEpicsWithColor from '../queries/group_epics_with_color.query.graphql';
import * as epicUtils from '../utils/epic_utils';
import * as roadmapItemUtils from '../utils/roadmap_item_utils';
import { getEpicsTimeframeRange, sortEpics } from '../utils/roadmap_utils';

import * as types from './mutation_types';

export const setInitialData = ({ commit }, data) => commit(types.SET_INITIAL_DATA, data);

const fetchGroupEpics = (
  { epicIid, fullPath, epicsState, sortedBy, presetType, filterParams, timeframe },
  { timeframe: defaultTimeframe, endCursor },
) => {
  let query;
  let variables = {
    fullPath,
    state: epicsState,
    sort: sortedBy,
    endCursor,
    ...getEpicsTimeframeRange({
      presetType,
      timeframe: defaultTimeframe || timeframe,
    }),
  };

  const transformedFilterParams = epicUtils.transformFetchEpicFilterParams(filterParams);

  // When epicIid is present,
  // Roadmap is being accessed from within an Epic,
  // and then we don't need to pass `transformedFilterParams`.
  if (epicIid) {
    query = epicChildEpics;
    variables.iid = epicIid;
    variables.withColor = Boolean(gon?.features?.epicColorHighlight);
  } else {
    query = gon?.features?.epicColorHighlight ? groupEpicsWithColor : groupEpics;
    variables = {
      ...variables,
      ...transformedFilterParams,
      first: ROADMAP_PAGE_SIZE,
    };

    if (transformedFilterParams?.epicIid) {
      variables.iid = transformedFilterParams.epicIid.split('::&').pop();
    }
    if (transformedFilterParams?.groupPath) {
      variables.fullPath = transformedFilterParams.groupPath;
      variables.includeDescendantGroups = false;
    }
  }

  return epicUtils.gqClient
    .query({
      query,
      variables,
    })
    .then(({ data }) => {
      const nodes = epicIid ? data?.group?.epic?.children?.nodes : data?.group?.epics?.nodes;

      return {
        rawEpics: nodes || [],
        pageInfo: data?.group?.epics?.pageInfo,
      };
    });
};

export const receiveEpicsSuccess = (
  { commit, state },
  { rawEpics, pageInfo, timeframeExtended, appendToList },
) => {
  const epicIds = [];
  const epics = rawEpics.reduce((filteredEpics, epic) => {
    const { presetType, timeframe } = state;
    const formattedEpic = roadmapItemUtils.formatRoadmapItemDetails(
      epic,
      roadmapItemUtils.timeframeStartDate(presetType, timeframe),
      roadmapItemUtils.timeframeEndDate(presetType, timeframe),
    );

    formattedEpic.isChildEpic = false;

    // Exclude any Epic that has invalid dates
    // or is already present in Roadmap timeline
    if (
      formattedEpic.startDate.getTime() <= formattedEpic.endDate.getTime() &&
      state.epicIds.indexOf(formattedEpic.id) < 0
    ) {
      filteredEpics.push(formattedEpic);
      epicIds.push(formattedEpic.id);
    }
    return filteredEpics;
  }, []);

  commit(types.UPDATE_EPIC_IDS, epicIds);

  if (timeframeExtended) {
    const updatedEpics = state.epics.concat(epics);
    sortEpics(updatedEpics, state.sortedBy);
    commit(types.RECEIVE_EPICS_FOR_TIMEFRAME_SUCCESS, updatedEpics);
  } else if (appendToList) {
    const updatedEpics = state.epics.concat(epics);
    commit(types.RECEIVE_EPICS_FOR_NEXT_PAGE_SUCCESS, { epics: updatedEpics, pageInfo });
  } else {
    commit(types.RECEIVE_EPICS_SUCCESS, { epics, pageInfo });
  }
};
export const receiveEpicsFailure = ({ commit }) => {
  commit(types.RECEIVE_EPICS_FAILURE);
  createAlert({
    message: s__('GroupRoadmap|Something went wrong while fetching epics'),
  });
};

export const fetchEpics = ({ state, commit, dispatch }, { endCursor } = {}) => {
  if (endCursor) {
    commit(types.REQUEST_EPICS_FOR_NEXT_PAGE);
  } else {
    commit(types.REQUEST_EPICS);
  }

  return fetchGroupEpics(state, { endCursor })
    .then(({ rawEpics, pageInfo }) => {
      dispatch('receiveEpicsSuccess', {
        rawEpics,
        pageInfo,
        appendToList: Boolean(endCursor),
      });
    })
    .catch(() => dispatch('receiveEpicsFailure'));
};

export const setBufferSize = ({ commit }, bufferSize) => commit(types.SET_BUFFER_SIZE, bufferSize);

export const setEpicsState = ({ commit }, epicsState) => commit(types.SET_EPICS_STATE, epicsState);

export const setDaterange = ({ commit }, { timeframeRangeType, presetType }) =>
  commit(types.SET_DATERANGE, { timeframeRangeType, presetType });

export const setFilterParams = ({ commit }, filterParams) =>
  commit(types.SET_FILTER_PARAMS, filterParams);

export const setSortedBy = ({ commit }, sortedBy) => commit(types.SET_SORTED_BY, sortedBy);

export const setProgressTracking = ({ commit }, progressTracking) =>
  commit(types.SET_PROGRESS_TRACKING, progressTracking);

export const toggleProgressTrackingActive = ({ commit }) =>
  commit(types.TOGGLE_PROGRESS_TRACKING_ACTIVE);

export const setMilestonesType = ({ commit }, milestonesType) =>
  commit(types.SET_MILESTONES_TYPE, milestonesType);

export const toggleMilestones = ({ commit }) => commit(types.TOGGLE_MILESTONES);

export const toggleLabels = ({ commit }) => commit(types.TOGGLE_LABELS);

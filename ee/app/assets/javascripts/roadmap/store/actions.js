import * as types from './mutation_types';

export const setInitialData = ({ commit }, data) => commit(types.SET_INITIAL_DATA, data);

export const setBufferSize = ({ commit }, bufferSize) => commit(types.SET_BUFFER_SIZE, bufferSize);

export const setEpicsState = ({ commit }, epicsState) => commit(types.SET_EPICS_STATE, epicsState);

export const setDaterange = ({ commit }, { timeframeRangeType, presetType }) =>
  commit(types.SET_DATERANGE, { timeframeRangeType, presetType });

export const setSortedBy = ({ commit }, sortedBy) => commit(types.SET_SORTED_BY, sortedBy);

export const setProgressTracking = ({ commit }, progressTracking) =>
  commit(types.SET_PROGRESS_TRACKING, progressTracking);

export const toggleProgressTrackingActive = ({ commit }) =>
  commit(types.TOGGLE_PROGRESS_TRACKING_ACTIVE);

export const setMilestonesType = ({ commit }, milestonesType) =>
  commit(types.SET_MILESTONES_TYPE, milestonesType);

export const toggleMilestones = ({ commit }) => commit(types.TOGGLE_MILESTONES);

export const toggleLabels = ({ commit }) => commit(types.TOGGLE_LABELS);

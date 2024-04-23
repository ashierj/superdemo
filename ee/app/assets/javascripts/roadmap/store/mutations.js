import { getTimeframeForRangeType } from '../utils/roadmap_utils';
import * as types from './mutation_types';

const resetEpics = (state) => {
  state.epics = [];
  state.epicIds = [];
};

export default {
  [types.SET_INITIAL_DATA](state, data) {
    Object.assign(state, { ...data });
  },

  [types.SET_BUFFER_SIZE](state, bufferSize) {
    state.bufferSize = bufferSize;
  },

  [types.SET_EPICS_STATE](state, epicsState) {
    state.epicsState = epicsState;
    resetEpics(state);
  },

  [types.SET_DATERANGE](state, { timeframeRangeType, presetType }) {
    state.timeframeRangeType = timeframeRangeType;
    state.presetType = presetType;
    state.timeframe = getTimeframeForRangeType({
      timeframeRangeType,
      presetType,
    });
    resetEpics(state);
  },

  [types.SET_SORTED_BY](state, sortedBy) {
    state.sortedBy = sortedBy;
    resetEpics(state);
  },

  [types.SET_PROGRESS_TRACKING](state, progressTracking) {
    state.progressTracking = progressTracking;
  },

  [types.TOGGLE_PROGRESS_TRACKING_ACTIVE](state) {
    state.isProgressTrackingActive = !state.isProgressTrackingActive;
  },

  [types.SET_MILESTONES_TYPE](state, milestonesType) {
    state.milestonesType = milestonesType;
  },

  [types.TOGGLE_MILESTONES](state) {
    state.isShowingMilestones = !state.isShowingMilestones;
  },

  [types.TOGGLE_LABELS](state) {
    state.isShowingLabels = !state.isShowingLabels;
  },
};

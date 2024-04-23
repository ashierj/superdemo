import * as types from 'ee/roadmap/store/mutation_types';
import mutations from 'ee/roadmap/store/mutations';

import { PROGRESS_COUNT, MILESTONES_GROUP } from 'ee/roadmap/constants';
import defaultState from 'ee/roadmap/store/state';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import { basePath, mockSortedBy, mockEpic } from 'ee_jest/roadmap/mock_data';

const setEpicMockData = (state) => {
  state.epics = [mockEpic];
  state.epicIds = ['gid://gitlab/Epic/1'];
};

describe('Roadmap Store Mutations', () => {
  let state;

  beforeEach(() => {
    state = defaultState();
  });

  describe('SET_INITIAL_DATA', () => {
    it('Should set initial Roadmap data to state', () => {
      const initialData = {
        sortedBy: mockSortedBy,
        extendedTimeframe: [],
        filterQueryString: '',
        epicsState: 'all',
        basePath,
      };

      mutations[types.SET_INITIAL_DATA](state, initialData);

      expect(state).toEqual(expect.objectContaining(initialData));
    });
  });

  describe('SET_BUFFER_SIZE', () => {
    it('Should set `bufferSize` in state', () => {
      const bufferSize = 10;

      mutations[types.SET_BUFFER_SIZE](state, bufferSize);

      expect(state.bufferSize).toBe(bufferSize);
    });
  });

  describe('SET_EPICS_STATE', () => {
    it('Should set `epicsState` to the state and reset existing epics', () => {
      const epicsState = 'all';
      setEpicMockData(state);

      mutations[types.SET_EPICS_STATE](state, epicsState);

      expect(state).toMatchObject({
        epicsState,
        epics: [],
        epicIds: [],
      });
    });
  });

  describe('SET_DATERANGE', () => {
    it('Should set `timeframeRangeType`, `presetType` and `timeframe` to the state and reset existing epics', () => {
      const timeframeRangeType = 'CURRENT_YEAR';
      const presetType = 'MONTHS';
      setEpicMockData(state);

      mutations[types.SET_DATERANGE](state, { timeframeRangeType, presetType });

      expect(state).toMatchObject({
        timeframeRangeType,
        presetType,
        timeframe: getTimeframeForRangeType({
          timeframeRangeType,
          presetType,
        }),
        epics: [],
        epicIds: [],
      });
    });
  });

  describe('SET_SORTED_BY', () => {
    it('Should set `sortedBy` to the state and reset existing parent epics and children epics', () => {
      const sortedBy = 'start_date_asc';
      setEpicMockData(state);

      mutations[types.SET_SORTED_BY](state, sortedBy);

      expect(state).toMatchObject({
        epicIds: [],
        epics: [],
        sortedBy,
      });
    });
  });

  describe('SET_PROGRESS_TRACKING', () => {
    it('Should set `progressTracking` to the state', () => {
      const progressTracking = PROGRESS_COUNT;

      mutations[types.SET_PROGRESS_TRACKING](state, progressTracking);

      expect(state).toMatchObject({
        progressTracking,
      });
    });
  });

  describe('TOGGLE_PROGRESS_TRACKING_ACTIVE', () => {
    it('Should toggle `progressTracking` on state', () => {
      expect(state).toMatchObject({
        isProgressTrackingActive: true,
      });

      mutations[types.TOGGLE_PROGRESS_TRACKING_ACTIVE](state);

      expect(state).toMatchObject({
        isProgressTrackingActive: false,
      });
    });
  });

  describe('SET_MILESTONES_TYPE', () => {
    it('Should set `milestonesType` to the state', () => {
      const milestonesType = MILESTONES_GROUP;
      setEpicMockData(state);

      mutations[types.SET_MILESTONES_TYPE](state, milestonesType);

      expect(state).toMatchObject({
        milestonesType,
      });
    });
  });

  describe('TOGGLE_MILESTONES', () => {
    it('Should toggle `isShowingMilestones` on state', () => {
      expect(state).toMatchObject({
        isShowingMilestones: true,
      });

      mutations[types.TOGGLE_MILESTONES](state);

      expect(state).toMatchObject({
        isShowingMilestones: false,
      });
    });
  });

  describe('TOGGLE_LABELS', () => {
    it('Should toggle `isShowingLabels` on state', () => {
      expect(state).toMatchObject({
        isShowingLabels: false,
      });

      mutations[types.TOGGLE_LABELS](state);

      expect(state).toMatchObject({
        isShowingLabels: true,
      });
    });
  });
});

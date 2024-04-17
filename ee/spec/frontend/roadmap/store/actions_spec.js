import { DATE_RANGES, PRESET_TYPES, MILESTONES_GROUP } from 'ee/roadmap/constants';
import * as actions from 'ee/roadmap/store/actions';
import * as types from 'ee/roadmap/store/mutation_types';
import defaultState from 'ee/roadmap/store/state';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';
import testAction from 'helpers/vuex_action_helper';
import { mockGroupId, basePath, mockTimeframeInitialDate, mockSortedBy } from '../mock_data';

jest.mock('~/alert');

const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});

describe('Roadmap Vuex Actions', () => {
  const timeframeStartDate = mockTimeframeMonths[0];
  const timeframeEndDate = mockTimeframeMonths[mockTimeframeMonths.length - 1];
  let state;

  beforeEach(() => {
    state = {
      ...defaultState(),
      groupId: mockGroupId,
      timeframe: mockTimeframeMonths,
      presetType: PRESET_TYPES.MONTHS,
      sortedBy: mockSortedBy,
      filterQueryString: '',
      basePath,
      timeframeStartDate,
      timeframeEndDate,
      filterParams: {
        milestoneTitle: '',
      },
    };
  });

  describe('setInitialData', () => {
    it('should set initial roadmap props', () => {
      const mockRoadmap = {
        foo: 'bar',
        bar: 'baz',
      };

      return testAction(
        actions.setInitialData,
        mockRoadmap,
        {},
        [{ type: types.SET_INITIAL_DATA, payload: mockRoadmap }],
        [],
      );
    });
  });

  describe('setBufferSize', () => {
    it('should set bufferSize in store state', () => {
      return testAction(
        actions.setBufferSize,
        10,
        state,
        [{ type: types.SET_BUFFER_SIZE, payload: 10 }],
        [],
      );
    });
  });

  describe('setDaterange', () => {
    it('should set epicsState in store state', () => {
      return testAction(
        actions.setDaterange,
        { timeframeRangeType: 'CURRENT_YEAR', presetType: 'MONTHS' },
        state,
        [
          {
            type: types.SET_DATERANGE,
            payload: { timeframeRangeType: 'CURRENT_YEAR', presetType: 'MONTHS' },
          },
        ],
      );
    });
  });

  describe('setProgressTracking', () => {
    it('should set progressTracking in store state', () => {
      return testAction(
        actions.setProgressTracking,
        'COUNT',
        state,
        [{ type: types.SET_PROGRESS_TRACKING, payload: 'COUNT' }],
        [],
      );
    });
  });

  describe('toggleProgressTrackingActive', () => {
    it('commit TOGGLE_PROGRESS_TRACKING_ACTIVE mutation', () => {
      return testAction(
        actions.toggleProgressTrackingActive,
        undefined,
        state,
        [{ type: types.TOGGLE_PROGRESS_TRACKING_ACTIVE }],
        [],
      );
    });
  });

  describe('setMilestonesType', () => {
    it('should set milestonesType in store state', () => {
      return testAction(
        actions.setMilestonesType,
        MILESTONES_GROUP,
        state,
        [{ type: types.SET_MILESTONES_TYPE, payload: MILESTONES_GROUP }],
        [],
      );
    });
  });

  describe('toggleMilestones', () => {
    it('commit TOGGLE_MILESTONES mutation', () => {
      return testAction(
        actions.toggleMilestones,
        undefined,
        state,
        [{ type: types.TOGGLE_MILESTONES }],
        [],
      );
    });
  });

  describe('toggleLabels', () => {
    it('commit TOGGLE_LABELS mutation', () => {
      return testAction(
        actions.toggleLabels,
        undefined,
        state,
        [{ type: types.TOGGLE_LABELS }],
        [],
      );
    });
  });
});

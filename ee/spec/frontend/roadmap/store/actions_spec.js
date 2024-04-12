import MockAdapter from 'axios-mock-adapter';
import { DATE_RANGES, PRESET_TYPES, MILESTONES_GROUP } from 'ee/roadmap/constants';
import epicChildEpics from 'ee/roadmap/queries/epic_child_epics.query.graphql';
import * as actions from 'ee/roadmap/store/actions';
import * as types from 'ee/roadmap/store/mutation_types';
import defaultState from 'ee/roadmap/store/state';
import * as epicUtils from 'ee/roadmap/utils/epic_utils';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import {
  mockGroupId,
  basePath,
  mockTimeframeInitialDate,
  mockRawEpic,
  mockRawEpic2,
  mockFormattedEpic,
  mockFormattedEpic2,
  mockSortedBy,
  mockGroupEpicsQueryResponse,
  mockGroupEpics,
  mockPageInfo,
} from '../mock_data';

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

  describe('receiveEpicsSuccess', () => {
    it('should set formatted epics array and epicId to IDs array in state based on provided epics list', () => {
      return testAction(
        actions.receiveEpicsSuccess,
        {
          rawEpics: [mockRawEpic2],
          pageInfo: mockPageInfo,
        },
        state,
        [
          {
            type: types.UPDATE_EPIC_IDS,
            payload: [mockRawEpic2.id],
          },
          {
            type: types.RECEIVE_EPICS_SUCCESS,
            payload: { epics: [mockFormattedEpic2], pageInfo: mockPageInfo },
          },
        ],
      );
    });

    it('should set formatted epics array and epicId to IDs array in state based on provided epics list when timeframe was extended', () => {
      return testAction(
        actions.receiveEpicsSuccess,
        {
          rawEpics: [mockRawEpic],
          timeframeExtended: true,
        },
        state,
        [
          { type: types.UPDATE_EPIC_IDS, payload: [mockRawEpic.id] },
          {
            type: types.RECEIVE_EPICS_FOR_TIMEFRAME_SUCCESS,
            payload: [{ ...mockFormattedEpic }],
          },
        ],
      );
    });
  });

  describe('receiveEpicsFailure', () => {
    it('should set epicsFetchInProgress, epicsFetchForTimeframeInProgress to false and epicsFetchFailure to true', () => {
      return testAction(
        actions.receiveEpicsFailure,
        {},
        state,
        [{ type: types.RECEIVE_EPICS_FAILURE }],
        [],
      );
    });

    it('should show alert error', () => {
      actions.receiveEpicsFailure({ commit: () => {} });

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while fetching epics',
      });
    });
  });

  describe('fetchEpics', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      beforeEach(() => {
        jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(
          Promise.resolve({
            data: mockGroupEpicsQueryResponse.data,
          }),
        );
      });

      describe.each([true, false])(
        'when the epicColorHighlight feature flag enabled is %s',
        (withColorEnabled) => {
          beforeEach(() => {
            window.gon = { features: { epicColorHighlight: withColorEnabled } };
          });

          it('calls query', async () => {
            state.epicIid = 7;
            await actions.fetchEpics({ state, commit: jest.fn(), dispatch: jest.fn() });

            expect(epicUtils.gqClient.query).toHaveBeenCalledWith({
              query: epicChildEpics,
              variables: {
                endCursor: undefined,
                fullPath: '',
                iid: state.epicIid,
                sort: state.sortedBy,
                state: state.epicsState,
                timeframe: {
                  start: '2018-01-01',
                  end: '2018-12-31',
                },
                withColor: withColorEnabled,
              },
            });
          });
        },
      );

      it('should perform REQUEST_EPICS mutation dispatch receiveEpicsSuccess action when request is successful', () => {
        return testAction(
          actions.fetchEpics,
          {},
          state,
          [
            {
              type: types.REQUEST_EPICS,
            },
          ],
          [
            {
              type: 'receiveEpicsSuccess',
              payload: { rawEpics: mockGroupEpics, pageInfo: mockPageInfo, appendToList: false },
            },
          ],
        );
      });
    });

    describe('failure', () => {
      it('should perform REQUEST_EPICS mutation and dispatch receiveEpicsFailure action when request fails', () => {
        jest.spyOn(epicUtils.gqClient, 'query').mockRejectedValue(new Error('error message'));

        return testAction(
          actions.fetchEpics,
          {},
          state,
          [
            {
              type: types.REQUEST_EPICS,
            },
          ],
          [
            {
              type: 'receiveEpicsFailure',
            },
          ],
        );
      });
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

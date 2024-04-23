import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';

import { createAlert } from '~/alert';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import RoadmapShell from 'ee/roadmap/components/roadmap_shell.vue';
import MilestonesListSection from 'ee/roadmap/components/milestones_list_section.vue';
import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';
import eventHub from 'ee/roadmap/event_hub';
import createStore from 'ee/roadmap/store';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import groupMilestonesQuery from 'ee/roadmap/queries/group_milestones.query.graphql';

import {
  mockEpic,
  mockTimeframeInitialDate,
  mockGroupMilestonesQueryResponse,
  mockGroupMilestonesQueryResponseWithInvalidDates,
} from 'ee_jest/roadmap/mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);
Vue.use(Vuex);

const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});
const presetType = PRESET_TYPES.MONTHS;
const timeframeRangeType = DATE_RANGES.CURRENT_YEAR;

const groupMilestonesQueryHandler = jest.fn().mockResolvedValue(mockGroupMilestonesQueryResponse);

describe('RoadmapShell', () => {
  let store;
  let wrapper;

  const findRoadmapShellWrapper = () => wrapper.findByTestId('roadmap-shell');
  const findMilestonesListSection = () => wrapper.findComponent(MilestonesListSection);

  const storeFactory = () => {
    store = createStore();
    store.dispatch('setInitialData', {
      timeframe: mockTimeframeMonths,
      presetType,
      timeframeRangeType,
      isShowingMilestones: false,
      filterParams: {
        milestoneTitle: '',
      },
    });
  };

  const createComponent = ({ epics = [mockEpic], timeframe = mockTimeframeMonths } = {}) => {
    wrapper = shallowMountExtended(RoadmapShell, {
      store,
      attachTo: document.body,
      propsData: {
        presetType: PRESET_TYPES.MONTHS,
        epics,
        timeframe,
        filterParams: {},
        epicsFetchNextPageInProgress: false,
        hasNextPage: false,
      },
      provide: {
        fullPath: 'gitlab-org',
        epicIid: null,
      },
      apolloProvider: createMockApollo([[groupMilestonesQuery, groupMilestonesQueryHandler]]),
    });
  };

  beforeEach(() => {
    storeFactory();
  });

  afterEach(() => {
    store = null;
  });

  it('sets container styles on component mount', async () => {
    createComponent();
    await nextTick();

    expect(findRoadmapShellWrapper().attributes('style')).toBe('height: calc(100vh - 0px);');
  });

  it('emits `epicListScrolled` event via event hub on scroll', () => {
    jest.spyOn(eventHub, '$emit').mockImplementation();

    createComponent();
    findRoadmapShellWrapper().trigger('scroll');

    expect(eventHub.$emit).toHaveBeenCalledWith('epicsListScrolled', {
      clientHeight: 0,
      scrollHeight: 0,
      scrollLeft: 0,
      scrollTop: 0,
    });
  });

  it('does not call milestones query if milestones are not shown', () => {
    createComponent();

    expect(groupMilestonesQueryHandler).not.toHaveBeenCalled();
  });

  describe('when milestones are shown', () => {
    beforeEach(() => {
      store.state.isShowingMilestones = true;
    });

    it('calls the groupMilestonesQuery with the correct timeframe', () => {
      createComponent();

      expect(groupMilestonesQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          timeframe: {
            end: '2018-12-31',
            start: '2018-01-01',
          },
        }),
      );
    });

    describe('when milestones query is successful', () => {
      it('renders the MilestonesListSection component', async () => {
        createComponent();
        await waitForPromises();

        expect(findMilestonesListSection().exists()).toBe(true);
      });

      it('passes the correct number of milestones to the MilestonesListSection component', async () => {
        createComponent();
        await waitForPromises();

        expect(findMilestonesListSection().props('milestones')).toHaveLength(2);
      });

      it('filters away a milestone with invalid dates', async () => {
        groupMilestonesQueryHandler.mockResolvedValue(
          mockGroupMilestonesQueryResponseWithInvalidDates,
        );

        createComponent();
        await waitForPromises();

        expect(findMilestonesListSection().props('milestones')).toHaveLength(1);
      });
    });

    describe('when milestones query is unsuccessful', () => {
      beforeEach(async () => {
        groupMilestonesQueryHandler.mockRejectedValue('Houston, we have a problem');

        createComponent();
        await waitForPromises();
      });

      it('does not render the MilestonesListSection component', () => {
        expect(findMilestonesListSection().exists()).toBe(false);
      });

      it('creates an alert', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Something went wrong while fetching milestones',
        });
      });
    });
  });
});

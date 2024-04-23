import { shallowMount } from '@vue/test-utils';

import EpicItem from 'ee/roadmap/components/epic_item.vue';
import EpicItemContainer from 'ee/roadmap/components/epic_item_container.vue';

import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';
import createStore from 'ee/roadmap/store';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import {
  mockTimeframeInitialDate,
  mockGroupId,
  mockFormattedChildEpic1,
} from 'ee_jest/roadmap/mock_data';

let store;

const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});

const createComponent = ({
  presetType = PRESET_TYPES.MONTHS,
  timeframe = mockTimeframeMonths,
  currentGroupId = mockGroupId,
  children = [],
  childLevel = 0,
} = {}) => {
  return shallowMount(EpicItemContainer, {
    store,
    stubs: {
      EpicItem: true,
    },
    provide: {
      currentGroupId,
    },
    propsData: {
      presetType,
      timeframe,
      currentGroupId,
      children,
      childLevel,
      filterParams: {},
    },
  });
};

describe('EpicItemContainer', () => {
  let wrapper;

  beforeEach(() => {
    store = createStore();
    wrapper = createComponent();
  });

  describe('template', () => {
    it('renders epic list container', () => {
      expect(wrapper.classes('epic-list-item-container')).toBe(true);
    });

    it('renders one Epic item element per child', () => {
      wrapper = createComponent({
        children: [mockFormattedChildEpic1],
      });

      expect(wrapper.findComponent(EpicItem).exists()).toBe(true);
      expect(wrapper.findAllComponents(EpicItem).length).toBe(1);
    });
  });
});

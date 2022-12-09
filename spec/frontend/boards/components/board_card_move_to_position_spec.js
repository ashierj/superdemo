import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';

import BoardCardMoveToPosition from '~/boards/components/board_card_move_to_position.vue';
import { mockList, mockIssue2, mockIssue, mockIssue3, mockIssue4 } from 'jest/boards/mock_data';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { BOARD_CARD_MOVE_TO_POSITION_OPTIONS } from '~/boards/constants';

Vue.use(Vuex);

const dropdownOptions = [
  BOARD_CARD_MOVE_TO_POSITION_OPTIONS[0].text,
  BOARD_CARD_MOVE_TO_POSITION_OPTIONS[1].text,
];

describe('Board Card Move to position', () => {
  let wrapper;
  let trackingSpy;
  let store;
  let dispatch;
  const itemIndex = 1;

  const createStoreOptions = () => {
    const state = {
      pageInfoByListId: {
        'gid://gitlab/List/1': {},
        'gid://gitlab/List/2': { hasNextPage: true },
      },
    };
    const getters = {
      getBoardItemsByList: () => () => [mockIssue, mockIssue2, mockIssue3, mockIssue4],
    };
    const actions = {
      moveItem: jest.fn(),
    };

    return {
      state,
      getters,
      actions,
    };
  };

  const createComponent = (propsData) => {
    wrapper = shallowMount(BoardCardMoveToPosition, {
      store,
      propsData: {
        item: mockIssue2,
        list: mockList,
        listItemsLength: 3,
        index: 0,
        ...propsData,
      },
      stubs: {
        GlCollapsibleListbox,
      },
    });
  };

  beforeEach(() => {
    store = new Vuex.Store(createStoreOptions());
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findMoveToPositionDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findDropdownItems = () => findMoveToPositionDropdown().findAllComponents(GlListboxItem);
  const findDropdownItemAtIndex = (index) => findDropdownItems().at(index);

  describe('Dropdown', () => {
    describe('Dropdown button', () => {
      it('has an icon with vertical ellipsis', () => {
        expect(findMoveToPositionDropdown().exists()).toBe(true);
        expect(findMoveToPositionDropdown().props('icon')).toBe('ellipsis_v');
      });

      it('is opened on the click of vertical ellipsis and has 2 dropdown items when number of list items < 10', () => {
        expect(findDropdownItems()).toHaveLength(dropdownOptions.length);
      });
    });

    describe('Dropdown options', () => {
      beforeEach(() => {
        createComponent({ index: itemIndex });
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
        dispatch = jest.spyOn(store, 'dispatch').mockImplementation(() => {});
      });

      afterEach(() => {
        unmockTracking();
      });

      it.each`
        dropdownIndex | dropdownLabel                                  | trackLabel         | positionInList
        ${0}          | ${BOARD_CARD_MOVE_TO_POSITION_OPTIONS[0].text} | ${'move_to_start'} | ${0}
        ${1}          | ${BOARD_CARD_MOVE_TO_POSITION_OPTIONS[1].text} | ${'move_to_end'}   | ${-1}
      `(
        'on click of dropdown index $dropdownIndex with label $dropdownLabel should call moveItem action with tracking label $trackLabel',
        async ({ dropdownIndex, dropdownLabel, trackLabel, positionInList }) => {
          await findMoveToPositionDropdown().vm.$emit(
            'select',
            BOARD_CARD_MOVE_TO_POSITION_OPTIONS[dropdownIndex].value,
          );
          expect(findDropdownItemAtIndex(dropdownIndex).text()).toBe(dropdownLabel);

          await nextTick();

          expect(trackingSpy).toHaveBeenCalledWith('boards:list', 'click_toggle_button', {
            category: 'boards:list',
            label: trackLabel,
            property: 'type_card',
          });
          expect(dispatch).toHaveBeenCalledWith('moveItem', {
            fromListId: mockList.id,
            itemId: mockIssue2.id,
            itemIid: mockIssue2.iid,
            itemPath: mockIssue2.referencePath,
            positionInList,
            toListId: mockList.id,
            allItemsLoadedInList: true,
            atIndex: itemIndex,
          });
        },
      );
    });
  });
});

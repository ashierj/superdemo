import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ItemActions from '~/groups/components/item_actions.vue';
import eventHub from '~/groups/event_hub';
import { mockParentGroupItem, mockChildren } from '../mock_data';

describe('ItemActions', () => {
  let wrapper;
  const parentGroup = mockChildren[0];

  const defaultProps = {
    group: mockParentGroupItem,
    parentGroup,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ItemActions, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findEditGroupBtn = () => wrapper.findByTestId(`edit-group-${mockParentGroupItem.id}-btn`);
  const findLeaveGroupBtn = () => wrapper.findByTestId(`leave-group-${mockParentGroupItem.id}-btn`);
  const findRemoveGroupBtn = () =>
    wrapper.findByTestId(`remove-group-${mockParentGroupItem.id}-btn`);

  describe('template', () => {
    let group;

    beforeEach(() => {
      group = {
        ...mockParentGroupItem,
        canEdit: true,
        canLeave: true,
        canRemove: true,
      };
      createComponent({ group });
    });

    it('renders component template correctly', () => {
      createComponent();

      expect(wrapper.classes()).toContain('gl-display-flex', 'gl-justify-content-end', 'gl-ml-5');
    });

    it('renders "Edit" group button with correct attribute values', () => {
      const button = findEditGroupBtn();
      expect(button.exists()).toBe(true);
      expect(button.attributes('href')).toBe(mockParentGroupItem.editPath);
    });

    it('renders "Delete" group button with correct attribute values', () => {
      const button = findRemoveGroupBtn();
      expect(button.exists()).toBe(true);
      expect(button.attributes('href')).toBe(
        `${mockParentGroupItem.editPath}#js-remove-group-form`,
      );
    });

    it('emits `showLeaveGroupModal` event in the event hub', () => {
      jest.spyOn(eventHub, '$emit');
      findLeaveGroupBtn().vm.$emit('click', { stopPropagation: () => {} });

      expect(eventHub.$emit).toHaveBeenCalledWith('showLeaveGroupModal', group, parentGroup);
    });
  });

  it('emits `showLeaveGroupModal` event with the correct prefix if `action` prop is passed', () => {
    const group = {
      ...mockParentGroupItem,
      canEdit: true,
      canLeave: true,
    };
    createComponent({
      group,
      action: 'test',
    });
    jest.spyOn(eventHub, '$emit');
    findLeaveGroupBtn().vm.$emit('click', { stopPropagation: () => {} });

    expect(eventHub.$emit).toHaveBeenCalledWith('testshowLeaveGroupModal', group, parentGroup);
  });

  it('does not render leave button if group can not be left', () => {
    createComponent({
      group: {
        ...mockParentGroupItem,
        canLeave: false,
      },
    });

    expect(findLeaveGroupBtn().exists()).toBe(false);
  });

  it('does not render edit button if group can not be edited', () => {
    createComponent({
      group: {
        ...mockParentGroupItem,
        canEdit: false,
      },
    });

    expect(findEditGroupBtn().exists()).toBe(false);
  });

  it('does not render delete button if group can not be edited', () => {
    createComponent({
      group: {
        ...mockParentGroupItem,
        canRemove: false,
      },
    });

    expect(findRemoveGroupBtn().exists()).toBe(false);
  });
});

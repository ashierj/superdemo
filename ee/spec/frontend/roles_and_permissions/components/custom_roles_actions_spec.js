import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CustomRolesActions from 'ee/roles_and_permissions/components/custom_roles_actions.vue';

const DEFAULT_CUSTOM_ROLE = { membersCount: 0 };

describe('CustomRolesActions', () => {
  let wrapper;

  const createComponent = ({ customRole = DEFAULT_CUSTOM_ROLE } = {}) => {
    wrapper = shallowMount(CustomRolesActions, {
      propsData: { customRole },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownItem = (index) =>
    findDropdown().findAllComponents(GlDisclosureDropdownItem).at(index);

  it('renders the actions dropdown', () => {
    createComponent();

    expect(findDropdown().props()).toMatchObject({
      icon: 'ellipsis_v',
      category: 'tertiary',
      placement: 'right',
    });
  });

  it('renders the edit role action item', () => {
    createComponent();

    expect(findDropdownItem(0).props('item')).toMatchObject({ text: 'Edit role' });
  });

  describe('delete action', () => {
    it('renders the action', () => {
      createComponent();

      expect(findDropdownItem(1).props('item')).toMatchObject({
        text: 'Delete role',
        extraAttrs: { class: 'gl-text-red-500!' },
      });
    });

    it('disables the action when there are assigned users', () => {
      createComponent({ customRole: { membersCount: 1 } });

      expect(findDropdownItem(1).props('item').extraAttrs.disabled).toBe(true);
    });
  });
});

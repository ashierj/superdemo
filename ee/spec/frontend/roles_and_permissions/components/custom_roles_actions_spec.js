import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CustomRolesActions from 'ee/roles_and_permissions/components/custom_roles_actions.vue';

describe('CustomRolesActions', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(CustomRolesActions);
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownItem = (index) =>
    findDropdown().findAllComponents(GlDisclosureDropdownItem).at(index);

  beforeEach(() => {
    createComponent();
  });

  it('renders the actions dropdown', () => {
    expect(findDropdown().exists()).toBe(true);

    expect(findDropdown().props()).toMatchObject({
      icon: 'ellipsis_v',
      category: 'tertiary',
      placement: 'right',
    });
  });

  it('renders the edit role action item', () => {
    expect(findDropdownItem(0).props('item')).toMatchObject({ text: 'Edit role' });
  });

  it('renders the delete role action item', () => {
    expect(findDropdownItem(1).props('item')).toMatchObject({
      text: 'Delete role',
      extraAttrs: { class: 'gl-text-red-500!' },
    });
  });
});

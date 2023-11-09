import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import GroupSelect from '~/vue_shared/components/entity_select/group_select.vue';
import ListMemberRoles from 'ee/roles_and_permissions/components/list_member_roles.vue';
import RolesAndPermissions from 'ee/roles_and_permissions/components/roles_and_permissions.vue';

describe('RolesAndPermissionsSaas', () => {
  let wrapper;
  const createComponent = ({ showGroupSelector = true } = {}) => {
    wrapper = shallowMount(RolesAndPermissions, {
      propsData: { groupId: '31', emptyText: 'empty', showGroupSelector },
    });
  };

  const findGroupSelect = () => wrapper.findComponent(GroupSelect);
  const findListMemberRoles = () => wrapper.findComponent(ListMemberRoles);

  it.each([true, false])(
    'shows/hides the group selector when showGroupSelector is %s',
    (showGroupSelector) => {
      createComponent({ showGroupSelector });

      expect(findGroupSelect().exists()).toBe(showGroupSelector);
    },
  );

  it('updates the group ID when group selector is changed', async () => {
    createComponent();

    expect(findListMemberRoles().props('groupId')).toBe('31');

    findGroupSelect().vm.$emit('input', { value: '32' });
    await nextTick();

    expect(findListMemberRoles().props('groupId')).toBe('32');
  });

  it('shows the ListMemberRoles component with the expected props', () => {
    createComponent();

    expect(findListMemberRoles().props()).toMatchObject({
      groupId: '31',
      emptyText: 'empty',
    });
  });
});

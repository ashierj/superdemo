import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import LdapDropdownFooter from 'ee/members/components/action_dropdowns/ldap_dropdown_footer.vue';
import { guestOverageConfirmAction } from 'ee/members/guest_overage_confirm_action';
import waitForPromises from 'helpers/wait_for_promises';
import MaxRole from '~/members/components/table/max_role.vue';
import { MEMBER_TYPES } from '~/members/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { upgradedMember as member } from '../../mock_data';

Vue.use(Vuex);

jest.mock('ee/members/guest_overage_confirm_action');
jest.mock('~/sentry/sentry_browser_wrapper');
guestOverageConfirmAction.mockResolvedValue(true);

describe('MaxRole', () => {
  let wrapper;
  let actions;

  const createStore = ({ updateMemberRoleReturn = () => Promise.resolve() } = {}) => {
    actions = {
      updateMemberRole: jest.fn(() => updateMemberRoleReturn()),
    };

    return new Vuex.Store({
      modules: {
        [MEMBER_TYPES.user]: { namespaced: true, actions },
      },
    });
  };
  const CustomPermissionsStub = {
    name: 'custompermissions-stub',
    template: '<div></div>',
  };

  const createComponent = (propsData = {}, store = createStore()) => {
    wrapper = mount(MaxRole, {
      provide: {
        namespace: MEMBER_TYPES.user,
        group: {
          name: 'groupname',
          path: '/grouppath/',
        },
      },
      propsData: {
        member,
        permissions: { canUpdate: true },
        ...propsData,
      },
      store,
      stubs: {
        CustomPermissions: CustomPermissionsStub,
      },
    });

    return waitForPromises();
  };

  const findCustomPermissions = () => wrapper.findComponent(CustomPermissionsStub);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxItems = () => wrapper.findAllComponents(GlListboxItem);
  const findListboxItemByText = (text) =>
    findListboxItems().wrappers.find((item) => item.text() === text);

  describe('when a member has custom permissions', () => {
    it('renders an initial list', async () => {
      await createComponent();

      expect(findCustomPermissions().exists()).toBe(true);
    });
  });

  describe('when member does not have custom permissions', () => {
    const myError = new Error('error');

    beforeEach(async () => {
      await createComponent(
        {
          member: {
            ...member,
            accessLevel: { integerValue: 50, stringValue: 'Owner', memberRoleId: null },
            customPermissions: [],
          },
        },
        createStore({ updateMemberRoleReturn: () => Promise.reject(myError) }),
      );
    });

    it('does not render a list', () => {
      expect(findCustomPermissions().exists()).toBe(false);
    });

    describe('after unsuccessful role assignment', () => {
      beforeEach(async () => {
        findListboxItemByText('custom role 2').trigger('click');
        await waitForPromises();
      });

      it('logs error to Sentry', () => {
        expect(Sentry.captureException).toHaveBeenCalledWith(myError);
      });

      it('resets selected dropdown item', () => {
        expect(findListbox().find('[aria-selected=true]').text()).toBe('Owner');
      });

      it('resets list of permissions', () => {
        expect(findCustomPermissions().exists()).toBe(false);
      });
    });
  });

  describe('when member has `canOverride` permissions', () => {
    describe('when member is overridden', () => {
      it('renders LDAP dropdown footer', async () => {
        await createComponent({
          permissions: {
            canUpdate: true,
            canOverride: true,
          },
          member: { ...member, isOverridden: true },
        });

        expect(wrapper.findComponent(LdapDropdownFooter).exists()).toBe(true);
      });
    });

    describe('when member is not overridden', () => {
      it('disables dropdown', () => {
        createComponent({
          permissions: {
            canUpdate: true,
            canOverride: true,
          },
          member: { ...member, isOverridden: false },
        });

        expect(findListbox().props('disabled')).toBeDefined();
      });
    });
  });

  describe('when member does not have `canOverride` permissions', () => {
    it('does not render LDAP dropdown footer', async () => {
      await createComponent({
        permissions: {
          canOverride: false,
        },
      });

      expect(wrapper.findComponent(LdapDropdownFooter).exists()).toBe(false);
    });
  });

  describe('when member has custom roles', () => {
    it('renders static and custom roles', () => {
      createComponent();

      expect(findListbox().props('items')[0].text).toBe('Standard roles');
      expect(findListbox().props('items')[0].options).toHaveLength(6);
      expect(findListbox().props('items')[1].text).toBe('Custom roles based on Guest');
      expect(findListbox().props('items')[1].options).toHaveLength(2);
      expect(findListbox().props('items')[2].text).toBe('Custom roles based on Reporter');
      expect(findListbox().props('items')[2].options).toHaveLength(1);
    });

    it('calls `updateMemberRole` Vuex action', async () => {
      createComponent();
      findListboxItemByText('custom role 3').trigger('click');
      await waitForPromises();

      expect(actions.updateMemberRole).toHaveBeenCalledWith(expect.any(Object), {
        memberId: member.id,
        accessLevel: 20,
        memberRoleId: 103,
      });
    });
  });

  describe('guestOverageConfirmAction', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('when guestOverageConfirmAction returns true', () => {
      beforeEach(async () => {
        guestOverageConfirmAction.mockResolvedValueOnce(true);
        findListboxItemByText('Reporter').trigger('click');
        await waitForPromises();
      });

      it('calls updateMemberRole', () => {
        expect(actions.updateMemberRole).toHaveBeenCalledWith(expect.any(Object), {
          memberId: member.id,
          accessLevel: 20,
          memberRoleId: null,
        });
      });
    });

    describe('when guestOverageConfirmAction returns false', () => {
      beforeEach(async () => {
        guestOverageConfirmAction.mockResolvedValueOnce(false);
        findListboxItemByText('custom role 3').trigger('click');
        await waitForPromises();
      });

      it('does not call updateMemberRole', () => {
        expect(guestOverageConfirmAction).toHaveBeenCalledWith({
          oldAccessLevel: 10,
          newRoleName: 'Reporter',
          newMemberRoleId: 103,
          group: { name: 'groupname', path: '/grouppath/' },
          memberId: 238,
          memberType: 'user',
        });
        expect(actions.updateMemberRole).not.toHaveBeenCalled();
      });

      it('re-enables dropdown', () => {
        expect(findListbox().props('loading')).toBe(false);
      });
    });

    describe('when guestOverageConfirmAction fails', () => {
      beforeEach(() => {
        guestOverageConfirmAction.mockRejectedValue('error');
      });

      it('logs error to Sentry', async () => {
        findListboxItemByText('Developer').trigger('click');
        await waitForPromises();

        expect(Sentry.captureException).toHaveBeenCalledWith('error');
      });
    });
  });
});

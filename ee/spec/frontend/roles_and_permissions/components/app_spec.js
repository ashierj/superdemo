import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';

import groupMemberRolesQuery from 'ee/invite_members/graphql/queries/group_member_roles.query.graphql';
import instanceMemberRolesQuery from 'ee/roles_and_permissions/graphql/instance_member_roles.query.graphql';
import deleteMemberRoleMutation from 'ee/roles_and_permissions/graphql/delete_member_role.mutation.graphql';

import CustomRolesApp from 'ee/roles_and_permissions/components/app.vue';
import CustomRolesEmptyState from 'ee/roles_and_permissions/components/custom_roles_empty_state.vue';
import CustomRolesTable from 'ee/roles_and_permissions/components/custom_roles_table.vue';
import CustomRolesDeleteModal from 'ee/roles_and_permissions/components/custom_roles_delete_modal.vue';

import { mockEmptyMemberRoles, mockMemberRoles, mockInstanceMemberRoles } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('CustomRolesApp', () => {
  let wrapper;

  const mockCustomRoleToDelete = mockMemberRoles.data.namespace.memberRoles.nodes[0];

  const mockToastShow = jest.fn();
  const groupRolesSuccessQueryHandler = jest.fn().mockResolvedValue(mockMemberRoles);
  const instanceRolesSuccessQueryHandler = jest.fn().mockResolvedValue(mockInstanceMemberRoles);
  const deleteMutationSuccessHandler = jest.fn().mockResolvedValue({
    data: {
      memberRoleDelete: {
        errors: [],
        memberRole: { id: mockCustomRoleToDelete.id },
      },
    },
  });

  const errorHandler = jest.fn().mockRejectedValue('error');

  const createComponent = ({
    groupRolesQueryHandler = groupRolesSuccessQueryHandler,
    instanceRolesQueryHandler = instanceRolesSuccessQueryHandler,
    deleteMutationHandler = deleteMutationSuccessHandler,
    groupFullPath = 'test-group',
  } = {}) => {
    wrapper = shallowMountExtended(CustomRolesApp, {
      apolloProvider: createMockApollo([
        [groupMemberRolesQuery, groupRolesQueryHandler],
        [instanceMemberRolesQuery, instanceRolesQueryHandler],
        [deleteMemberRoleMutation, deleteMutationHandler],
      ]),
      provide: {
        groupFullPath,
        documentationPath: 'http://foo.bar',
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  const findEmptyState = () => wrapper.findComponent(CustomRolesEmptyState);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTable = () => wrapper.findComponent(CustomRolesTable);
  const findHeader = () => wrapper.find('header');
  const findCount = () => wrapper.findByTestId('custom-roles-count');
  const findButton = () => wrapper.findComponent(GlButton);
  const findDeleteModal = () => wrapper.findComponent(CustomRolesDeleteModal);

  describe('on creation', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when data has loaded', () => {
    describe('and there are no custom roles', () => {
      beforeEach(async () => {
        createComponent({
          groupRolesQueryHandler: jest.fn().mockResolvedValue(mockEmptyMemberRoles),
        });

        await waitForPromises();
      });

      it('renders the empty state', () => {
        expect(findEmptyState().exists()).toBe(true);
      });
    });

    describe('and there group-level custom roles', () => {
      beforeEach(async () => {
        createComponent();

        await waitForPromises();
      });

      it('fetches group-level member roles', () => {
        expect(groupRolesSuccessQueryHandler).toHaveBeenCalledWith({
          fullPath: 'test-group',
        });
      });

      it('renders the title', () => {
        expect(findHeader().text()).toContain('Custom roles');
      });

      it('renders the new role button', () => {
        expect(findButton().text()).toContain('New role');
      });

      it('renders the number of roles', () => {
        expect(findCount().text()).toBe('2 Custom roles');
      });

      it('renders the table', () => {
        expect(findTable().exists()).toBe(true);

        expect(findTable().props('customRoles')).toEqual(
          mockMemberRoles.data.namespace.memberRoles.nodes,
        );
      });
    });

    describe('and there instance-level custom roles', () => {
      beforeEach(async () => {
        createComponent({
          groupFullPath: null,
        });

        await waitForPromises();
      });

      it('fetches instance-level member roles', () => {
        expect(instanceRolesSuccessQueryHandler).toHaveBeenCalledWith({});
      });

      it('renders the table', () => {
        expect(findTable().exists()).toBe(true);

        expect(findTable().props('customRoles')).toEqual(
          mockInstanceMemberRoles.data.memberRoles.nodes,
        );
      });
    });

    describe('and there is an error fetching the data', () => {
      beforeEach(async () => {
        createComponent({
          groupRolesQueryHandler: errorHandler,
        });

        await waitForPromises();
      });

      it('renders an error message', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Failed to fetch roles.',
        });
      });
    });
  });

  describe('when deleting a custom role', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('renders delete modal with `visible` set to false', () => {
      expect(findDeleteModal().exists()).toBe(true);
      expect(findDeleteModal().props('visible')).toBe(false);
    });

    describe('when table emits `delete-role` event', () => {
      beforeEach(() => {
        findTable().vm.$emit('delete-role', mockCustomRoleToDelete);
        return nextTick();
      });

      it('shows delete modal', () => {
        expect(findDeleteModal().props('visible')).toBe(true);
      });

      describe('when modal emits `delete` event', () => {
        beforeEach(() => {
          findDeleteModal().vm.$emit('delete');
        });

        it('calls the delete role mutation', () => {
          expect(deleteMutationSuccessHandler).toHaveBeenCalledWith({
            input: {
              id: mockCustomRoleToDelete.id,
            },
          });
        });

        it('renders the loader', () => {
          expect(findLoadingIcon().exists()).toBe(true);
          expect(findTable().exists()).toBe(false);
        });

        describe('when role is deleted successfully', () => {
          beforeEach(async () => {
            await waitForPromises();
          });

          it('renders toast', () => {
            expect(mockToastShow).toHaveBeenCalledWith('Role successfully deleted.');
          });

          it('refetches roles', () => {
            expect(groupRolesSuccessQueryHandler).toHaveBeenCalledTimes(2);
          });

          it('re-renders the table', () => {
            expect(findLoadingIcon().exists()).toBe(false);
            expect(findTable().exists()).toBe(true);
          });
        });
      });
    });
  });

  describe('when there is a client error deleting the role', () => {
    beforeEach(async () => {
      createComponent({
        deleteMutationHandler: jest.fn().mockResolvedValue({
          data: {
            memberRoleDelete: {
              errors: ['Role is assigned to one or more group members'],
            },
          },
        }),
      });

      await waitForPromises();
    });

    it('renders an error message', async () => {
      findTable().vm.$emit('delete-role', mockCustomRoleToDelete);
      findDeleteModal().vm.$emit('delete');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to delete role. Role is assigned to one or more group members',
      });
    });
  });

  describe('when there is a server error deleting the role', () => {
    beforeEach(async () => {
      createComponent({
        deleteMutationHandler: errorHandler,
      });

      await waitForPromises();
    });

    it('renders an error message', async () => {
      findTable().vm.$emit('delete-role', mockCustomRoleToDelete);
      findDeleteModal().vm.$emit('delete');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to delete role.',
      });
    });
  });
});

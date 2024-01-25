import { GlCard, GlEmptyState, GlModal, GlTable } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import groupMemberRolesQuery from 'ee/invite_members/graphql/queries/group_member_roles.query.graphql';
import instanceMemberRolesQuery from 'ee/roles_and_permissions/graphql/instance_member_roles.query.graphql';
import memberRolePermissionsQuery from 'ee/roles_and_permissions/graphql/member_role_permissions.query.graphql';
import deleteMemberRoleMutation from 'ee/roles_and_permissions/graphql/delete_member_role.mutation.graphql';
import CreateMemberRole from 'ee/roles_and_permissions/components/create_member_role.vue';
import ListMemberRoles from 'ee/roles_and_permissions/components/list_member_roles.vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  mockDefaultPermissions,
  mockPermissions,
  mockMemberRoles,
  mockInstanceMemberRoles,
} from '../mock_data';

Vue.use(VueApollo);

const mockAlertDismiss = jest.fn();

jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

describe('ListMemberRoles', () => {
  let wrapper;

  const mockToastShow = jest.fn();
  const groupRolesSuccessQueryHandler = jest.fn().mockResolvedValue(mockMemberRoles);
  const instanceRolesSuccessQueryHandler = jest.fn().mockResolvedValue(mockInstanceMemberRoles);
  const permissionsSuccessQueryHandler = jest.fn().mockResolvedValue(mockPermissions);
  const deleteMutationSuccessHandler = jest
    .fn()
    .mockResolvedValue({ data: { memberRoleDelete: { errors: null, memberRole: { id: '1' } } } });

  const failedQueryHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

  const createComponent = ({
    mountFn = shallowMountExtended,
    groupRolesQueryHandler = groupRolesSuccessQueryHandler,
    instanceRolesQueryHandler = instanceRolesSuccessQueryHandler,
    permissionsQueryHandler = permissionsSuccessQueryHandler,
    deleteMutationHandler = deleteMutationSuccessHandler,
    props = {},
  } = {}) => {
    wrapper = mountFn(ListMemberRoles, {
      apolloProvider: createMockApollo([
        [groupMemberRolesQuery, groupRolesQueryHandler],
        [instanceMemberRolesQuery, instanceRolesQueryHandler],
        [memberRolePermissionsQuery, permissionsQueryHandler],
        [deleteMemberRoleMutation, deleteMutationHandler],
      ]),
      propsData: {
        groupFullPath: 'test-group',
        ...props,
      },
      stubs: { GlCard, GlTable },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  const findTitle = () => wrapper.findByTestId('card-title');
  const findAddRoleButton = () => wrapper.findByTestId('add-role');
  const findButtonByText = (text) => wrapper.findByRole('button', { name: text });
  const findCounter = () => wrapper.findByTestId('counter');
  const findCreateMemberRole = () => wrapper.findComponent(CreateMemberRole);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findModal = () => wrapper.findComponent(GlModal);
  const findTable = () => wrapper.findComponent(GlTable);
  const findCellByText = (text) => wrapper.findByRole('cell', { name: text });
  const findCells = () => wrapper.findAllByRole('cell');

  const expectSortableColumn = (fieldKey) => {
    const fields = findTable().props('fields');
    expect(fields.find((field) => field.key === fieldKey)?.sortable).toBe(true);
  };

  describe('empty state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows empty state', () => {
      expect(findTitle().text()).toMatch('Custom roles');
      expect(findCounter().text()).toBe('0');

      expect(findAddRoleButton().props('disabled')).toBe(false);

      expect(findCreateMemberRole().exists()).toBe(false);
    });

    it('hides empty state when toggling the form', async () => {
      findAddRoleButton().vm.$emit('click');
      await waitForPromises();

      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('group-level member roles', () => {
    beforeEach(() => {
      createComponent();
    });

    it('fetches member roles', async () => {
      await waitForPromises();

      expect(groupRolesSuccessQueryHandler).toHaveBeenCalledWith({
        fullPath: 'test-group',
      });
    });

    describe('when there is an error fetching roles', () => {
      beforeEach(() => {
        createComponent({ groupRolesQueryHandler: failedQueryHandler });
      });

      it('shows alert when there is an error', async () => {
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'Failed to fetch roles: GraphQL error',
        });
      });
    });
  });

  describe('instance-level member roles', () => {
    beforeEach(() => {
      createComponent({ props: { groupFullPath: null } });
    });

    it('fetches member roles', async () => {
      await waitForPromises();

      expect(instanceRolesSuccessQueryHandler).toHaveBeenCalled();
    });

    describe('when there is an error fetching roles', () => {
      beforeEach(() => {
        createComponent({
          props: { groupFullPath: null },
          instanceRolesQueryHandler: failedQueryHandler,
        });
      });

      it('shows alert when there is an error', async () => {
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'Failed to fetch roles: GraphQL error',
        });
      });
    });
  });

  describe('create role form', () => {
    beforeEach(() => {
      createComponent();
      findAddRoleButton().vm.$emit('click');
      return waitForPromises();
    });

    it('renders CreateMemberRole component', () => {
      expect(findCreateMemberRole().exists()).toBe(true);
      expect(findCreateMemberRole().props('availablePermissions')).toEqual(mockDefaultPermissions);
    });

    it('toggles display', async () => {
      findCreateMemberRole().vm.$emit('cancel');
      await nextTick();

      expect(findCreateMemberRole().exists()).toBe(false);
    });

    describe('when successfully creates a new role', () => {
      it('shows toast', () => {
        findCreateMemberRole().vm.$emit('success');

        expect(mockToastShow).toHaveBeenCalledWith('Role successfully created.');
      });
    });
  });

  describe('member roles table', () => {
    beforeEach(() => {
      createComponent({ mountFn: mountExtended });
      return waitForPromises();
    });

    it('shows name and id', () => {
      expect(findCellByText('Test').exists()).toBe(true);
      expect(findCellByText('1').exists()).toBe(true);
    });

    it('sorts columns by name', () => {
      expectSortableColumn('name');
    });

    it('sorts columns by ID', () => {
      expectSortableColumn('id');
    });

    it('sorts columns by base role', () => {
      expectSortableColumn('baseAccessLevel');
    });

    it('shows list of permissions', () => {
      const permissionsText = findCells().at(3).text();

      expect(permissionsText).toContain('Read code');
      expect(permissionsText).toContain('Read vulnerability');
    });
  });

  describe('deleting member role', () => {
    beforeEach(() => {
      createComponent({ mountFn: mountExtended });
      return waitForPromises();
    });

    it('shows confirm modal', async () => {
      expect(findModal().props('visible')).toBe(false);

      findButtonByText('Delete role').trigger('click');
      await nextTick();

      expect(findModal().props('visible')).toBe(true);
    });

    describe('when the role is deleted successfully', () => {
      beforeEach(async () => {
        findButtonByText('Delete role').trigger('click');
        await nextTick();

        findModal().vm.$emit('primary');
        await waitForPromises();
      });

      it('delete the role', () => {
        expect(deleteMutationSuccessHandler).toHaveBeenCalledWith({
          input: {
            id: 'gid://gitlab/MemberRole/1',
          },
        });
      });

      it('shows toast', () => {
        expect(mockToastShow).toHaveBeenCalledWith('Role successfully deleted.');
      });

      it('refetches roles', () => {
        expect(groupRolesSuccessQueryHandler).toHaveBeenCalledTimes(2);
      });
    });

    describe('deleting instance-level member role', () => {
      beforeEach(() => {
        createComponent({ mountFn: mountExtended, props: { groupFullPath: null } });
        return waitForPromises();
      });

      describe('when the role is deleted successfully', () => {
        beforeEach(async () => {
          findButtonByText('Delete role').trigger('click');
          await nextTick();

          findModal().vm.$emit('primary');
          await waitForPromises();
        });

        it('delete the role', () => {
          expect(deleteMutationSuccessHandler).toHaveBeenCalledWith({
            input: {
              id: 'gid://gitlab/MemberRole/2',
            },
          });
        });

        it('shows toast', () => {
          expect(mockToastShow).toHaveBeenCalledWith('Role successfully deleted.');
        });

        it('refetches roles', () => {
          expect(instanceRolesSuccessQueryHandler).toHaveBeenCalledTimes(2);
        });
      });
    });

    describe('when there is an error deleting the role', () => {
      const mutationMock = jest.fn().mockResolvedValue({
        data: { memberRoleDelete: { errors: ['reason'], memberRole: null } },
      });

      beforeEach(async () => {
        createComponent({ deleteMutationHandler: mutationMock, mountFn: mountExtended });
        await waitForPromises();

        findButtonByText('Delete role').trigger('click');
        await nextTick();

        findModal().vm.$emit('primary');
        await waitForPromises();
      });

      it('shows alert', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Failed to delete role. reason',
        });
      });
    });
  });
});

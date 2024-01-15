import { GlCard, GlEmptyState, GlModal, GlTable } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import memberRolesQuery from 'ee/invite_members/graphql/queries/group_member_roles.query.graphql';
import memberRolePermissionsQuery from 'ee/roles_and_permissions/graphql/member_role_permissions.query.graphql';
import deleteMemberRoleMutation from 'ee/roles_and_permissions/graphql/delete_member_role.mutation.graphql';
import CreateMemberRole from 'ee/roles_and_permissions/components/create_member_role.vue';
import ListMemberRoles from 'ee/roles_and_permissions/components/list_member_roles.vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mockDefaultPermissions, mockPermissions, mockMemberRoles } from '../mock_data';

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
  const rolesSuccessQueryHandler = jest.fn().mockResolvedValue(mockMemberRoles);
  const permissionsSuccessQueryHandler = jest.fn().mockResolvedValue(mockPermissions);
  const deleteMutationSuccessHandler = jest
    .fn()
    .mockResolvedValue({ data: { memberRoleDelete: { errors: null, memberRole: { id: '1' } } } });

  const failedQueryHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

  const createComponent = ({
    mountFn = shallowMountExtended,
    rolesQueryHandler = rolesSuccessQueryHandler,
    permissionsQueryHandler = permissionsSuccessQueryHandler,
    deleteMutationHandler = deleteMutationSuccessHandler,
  } = {}) => {
    wrapper = mountFn(ListMemberRoles, {
      apolloProvider: createMockApollo([
        [memberRolesQuery, rolesQueryHandler],
        [memberRolePermissionsQuery, permissionsQueryHandler],
        [deleteMemberRoleMutation, deleteMutationHandler],
      ]),
      propsData: {
        emptyText: 'mock text',
        groupFullPath: 'test-group',
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

      expect(findEmptyState().props()).toMatchObject({
        description: 'mock text',
        title: 'No custom roles for this group',
      });

      expect(findCreateMemberRole().exists()).toBe(false);
    });

    it('hides empty state when toggling the form', async () => {
      findAddRoleButton().vm.$emit('click');
      await waitForPromises();

      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('member roles', () => {
    beforeEach(() => {
      createComponent();
    });

    it('fetches member roles', async () => {
      await waitForPromises();

      expect(rolesSuccessQueryHandler).toHaveBeenCalledWith({
        fullPath: 'test-group',
      });
    });

    describe('when groupFullPath is updated', () => {
      beforeEach(() => {
        wrapper.setProps({ groupFullPath: 'another-test-group' });
      });

      it('sets the `busy` attribute on the table to true', () => {
        expect(findTable().attributes('busy')).toBe('true');
      });

      it('refetches member roles', async () => {
        await waitForPromises();

        expect(rolesSuccessQueryHandler).toHaveBeenCalledWith({
          fullPath: 'another-test-group',
        });

        expect(findTable().attributes('busy')).toBeUndefined();
      });
    });

    describe('when there is an error fetching roles', () => {
      beforeEach(() => {
        createComponent({ rolesQueryHandler: failedQueryHandler });
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
        expect(rolesSuccessQueryHandler).toHaveBeenCalled();
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
          message: 'Failed to delete the role: reason',
        });
      });
    });
  });
});

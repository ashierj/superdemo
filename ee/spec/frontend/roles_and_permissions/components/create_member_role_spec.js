import { GlFormInput, GlFormSelect, GlFormTextarea, GlFormCheckbox } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { createAlert, VARIANT_DANGER } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import groupMemberRolesQuery from 'ee/invite_members/graphql/queries/group_member_roles.query.graphql';
import instanceMemberRolesQuery from 'ee/roles_and_permissions/graphql/instance_member_roles.query.graphql';
import createMemberRoleMutation from 'ee/roles_and_permissions/graphql/create_member_role.mutation.graphql';
import CreateMemberRole from 'ee/roles_and_permissions/components/create_member_role.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import { mockDefaultPermissions, mockMemberRoles, mockInstanceMemberRoles } from '../mock_data';

Vue.use(VueApollo);

const mockAlertDismiss = jest.fn();
jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

describe('CreateMemberRole', () => {
  let wrapper;

  const mutationSuccessHandler = jest
    .fn()
    .mockResolvedValue({ data: { memberRoleCreate: { errors: null, memberRole: { id: '1' } } } });

  const groupRolesQueryHandler = jest.fn().mockResolvedValue(mockMemberRoles);
  const instanceRolesQueryHandler = jest.fn().mockResolvedValue(mockInstanceMemberRoles);

  const createMockApolloProvider = (resolverMock) => {
    return createMockApollo([
      [groupMemberRolesQuery, groupRolesQueryHandler],
      [instanceMemberRolesQuery, instanceRolesQueryHandler],
      [createMemberRoleMutation, resolverMock],
    ]);
  };

  const createComponent = ({
    availablePermissions = mockDefaultPermissions,
    stubs = {},
    mutationMock = mutationSuccessHandler,
    props = {},
  } = {}) => {
    wrapper = mountExtended(CreateMemberRole, {
      propsData: {
        groupFullPath: 'test-group',
        availablePermissions,
        ...props,
      },
      stubs,
      apolloProvider: createMockApolloProvider(mutationMock),
    });
  };

  const findButtonSubmit = () => wrapper.findByTestId('submit-button');
  const findButtonCancel = () => wrapper.findByTestId('cancel-button');
  const findNameField = () => wrapper.findComponent(GlFormInput);
  const findCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findSelect = () => wrapper.findComponent(GlFormSelect);
  const findTextArea = () => wrapper.findComponent(GlFormTextarea);

  const fillForm = () => {
    findSelect().setValue('10');
    findNameField().setValue('My role name');
    findTextArea().setValue('My description');
    findCheckboxes().at(0).find('input').setChecked();
  };

  it('shows the role dropdown with the expected options', () => {
    // GlFormSelect doesn't stub the options prop properly, create a stub that does it properly.
    const stubs = { GlFormSelect: stubComponent(GlFormSelect, { props: ['options'] }) };
    createComponent({ stubs });

    expect(findSelect().props('options')).toEqual([
      { value: '10', text: 'Guest' },
      { value: '20', text: 'Reporter' },
      { value: '30', text: 'Developer' },
      { value: '40', text: 'Maintainer' },
      { value: '50', text: 'Owner' },
    ]);
  });

  it('has the expected permissions checkboxes', () => {
    createComponent();
    mockDefaultPermissions.forEach((permission, index) => {
      const checkbox = findCheckboxes().at(index);

      expect(checkbox.text()).toContain(permission.name);
      expect(checkbox.text()).toContain(permission.description);
    });
  });

  it('shows the manage project access token permission', () => {
    const permission = {
      name: 'Manage tokens',
      description: 'Manage tokens description',
      value: 'MANAGE_PROJECT_ACCESS_TOKENS',
    };

    createComponent({ availablePermissions: [permission] });

    const checkbox = findCheckboxes().at(0);

    expect(checkbox.text()).toContain('Manage tokens');
    expect(checkbox.text()).toContain('Manage tokens description');
  });

  it('emits cancel event', () => {
    createComponent();

    expect(wrapper.emitted('cancel')).toBeUndefined();

    findButtonCancel().trigger('click');

    expect(wrapper.emitted('cancel')).toHaveLength(1);
  });

  describe('field validation', () => {
    beforeEach(createComponent);

    it('shows a warning if no base role is selected', async () => {
      expect(findSelect().classes()).not.toContain('is-invalid');

      findButtonSubmit().trigger('submit');
      await nextTick();

      expect(findSelect().classes()).toContain('is-invalid');
    });

    it('shows a warning if name field is empty', async () => {
      expect(findNameField().classes()).toContain('is-valid');

      findButtonSubmit().trigger('submit');
      await nextTick();

      expect(findNameField().classes()).toContain('is-invalid');
    });

    it('shows a warning if permissions are unchecked', async () => {
      expect(findCheckboxes().at(0).find('input').classes()).not.toContain('is-invalid');

      findButtonSubmit().trigger('submit');
      await nextTick();

      expect(findCheckboxes().at(0).find('input').classes()).toContain('is-invalid');
    });
  });

  describe('when a group-level member-role is created successfully', () => {
    beforeEach(() => {
      createComponent();
      fillForm();
    });

    it('sends the correct data', async () => {
      findButtonSubmit().trigger('submit');
      await waitForPromises();

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          baseAccessLevel: 'GUEST',
          name: 'My role name',
          description: 'My description',
          permissions: ['READ_CODE'],
          groupPath: 'test-group',
        },
      });
    });

    it('emits success event', async () => {
      expect(wrapper.emitted('success')).toBeUndefined();

      findButtonSubmit().trigger('submit');
      await waitForPromises();

      expect(wrapper.emitted('success')).toHaveLength(1);
    });

    it('refetches roles', async () => {
      findButtonSubmit().trigger('submit');
      await waitForPromises();

      expect(groupRolesQueryHandler).toHaveBeenCalled();
    });
  });

  describe('when an instance-level member-role is created successfully', () => {
    beforeEach(() => {
      createComponent({ props: { groupFullPath: null } });
      fillForm();
    });

    it('sends the correct data', async () => {
      findButtonSubmit().trigger('submit');
      await waitForPromises();

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          baseAccessLevel: 'GUEST',
          name: 'My role name',
          description: 'My description',
          permissions: ['READ_CODE'],
        },
      });
    });

    it('emits success event', async () => {
      expect(wrapper.emitted('success')).toBeUndefined();

      findButtonSubmit().trigger('submit');
      await waitForPromises();

      expect(wrapper.emitted('success')).toHaveLength(1);
    });

    it('refetches roles', async () => {
      findButtonSubmit().trigger('submit');
      await waitForPromises();

      expect(instanceRolesQueryHandler).toHaveBeenCalled();
    });
  });

  describe('when there is an error creating the role', () => {
    const mutationMock = jest
      .fn()
      .mockResolvedValue({ data: { memberRoleCreate: { errors: ['reason'], memberRole: null } } });

    beforeEach(() => {
      createComponent({ mutationMock });
      fillForm();
    });

    it('shows alert', async () => {
      findButtonSubmit().trigger('submit');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to create role: reason',
        variant: VARIANT_DANGER,
      });
    });

    it('dismisses previous alert', async () => {
      findButtonSubmit().trigger('submit');
      await waitForPromises();

      expect(mockAlertDismiss).toHaveBeenCalledTimes(0);

      findButtonSubmit().trigger('submit');

      expect(mockAlertDismiss).toHaveBeenCalledTimes(1);
    });
  });
});

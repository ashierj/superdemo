import {
  GlFormInput,
  GlFormSelect,
  GlFormTextarea,
  GlFormCheckbox,
  GlFormCheckboxGroup,
  GlSkeletonLoader,
} from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import createMemberRoleMutation from 'ee/roles_and_permissions/graphql/create_member_role.mutation.graphql';
import CreateMemberRole from 'ee/roles_and_permissions/components/create_member_role.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import memberRolePermissionsQuery from 'ee/roles_and_permissions/graphql/member_role_permissions.query.graphql';
import { mockPermissions, mockDefaultPermissions } from '../mock_data';

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
    .mockResolvedValue({ data: { memberRoleCreate: { errors: [] } } });

  const defaultAvailablePermissionsHandler = jest.fn().mockResolvedValue(mockPermissions);

  const createComponent = ({
    stubs,
    mutationMock = mutationSuccessHandler,
    availablePermissionsHandler = defaultAvailablePermissionsHandler,
    groupFullPath = 'test-group',
  } = {}) => {
    wrapper = mountExtended(CreateMemberRole, {
      propsData: { groupFullPath },
      stubs,
      apolloProvider: createMockApollo([
        [memberRolePermissionsQuery, availablePermissionsHandler],
        [createMemberRoleMutation, mutationMock],
      ]),
    });

    return waitForPromises();
  };

  const findButtonSubmit = () => wrapper.findByTestId('submit-button');
  const findButtonCancel = () => wrapper.findByTestId('cancel-button');
  const findNameField = () => wrapper.findComponent(GlFormInput);
  const findCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findSelect = () => wrapper.findComponent(GlFormSelect);
  const findTextArea = () => wrapper.findComponent(GlFormTextarea);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  const fillForm = () => {
    findSelect().setValue('GUEST');
    findNameField().setValue('My role name');
    findTextArea().setValue('My description');
    findCheckboxes().at(0).find('input').setChecked();

    return nextTick();
  };

  const submitForm = (waitFn = nextTick) => {
    findButtonSubmit().trigger('submit');
    return waitFn();
  };

  it('shows the role dropdown with the expected options', () => {
    // GlFormSelect doesn't stub the options prop properly, create a stub that does it properly.
    const stubs = { GlFormSelect: stubComponent(GlFormSelect, { props: ['options'] }) };
    createComponent({ stubs });

    expect(findSelect().props('options')).toEqual([
      { value: 'GUEST', text: 'Guest' },
      { value: 'REPORTER', text: 'Reporter' },
      { value: 'DEVELOPER', text: 'Developer' },
      { value: 'MAINTAINER', text: 'Maintainer' },
      { value: 'OWNER', text: 'Owner' },
    ]);
  });

  it('emits cancel event when the cancel button is clicked', () => {
    createComponent();

    expect(wrapper.emitted('cancel')).toBeUndefined();

    findButtonCancel().trigger('click');

    expect(wrapper.emitted('cancel')).toHaveLength(1);
  });

  describe('available permissions', () => {
    it('loads the available permissions', () => {
      createComponent();

      expect(defaultAvailablePermissionsHandler).toHaveBeenCalledTimes(1);
    });

    it('shows the GlSkeletonLoader when the query is loading', () => {
      createComponent();

      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findCheckboxes()).toHaveLength(0);
    });

    it('shows the expected permissions when loaded', async () => {
      await createComponent();

      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findCheckboxes()).toHaveLength(mockDefaultPermissions.length);

      mockDefaultPermissions.forEach((permission, index) => {
        const checkboxText = findCheckboxes().at(index).text();

        expect(checkboxText).toContain(permission.name);
        expect(checkboxText).toContain(permission.description);
      });
    });

    it('shows an error if the query fails', async () => {
      const availablePermissionsHandler = jest.fn().mockRejectedValue(new Error('failed'));
      await createComponent({ availablePermissionsHandler });

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Could not fetch available permissions.',
      });
    });
  });

  describe('field validation', () => {
    beforeEach(createComponent);

    it('shows a warning if no base role is selected', async () => {
      expect(findSelect().classes()).not.toContain('is-invalid');

      await submitForm();

      expect(findSelect().classes()).toContain('is-invalid');
    });

    it('shows a warning if name field is empty', async () => {
      expect(findNameField().classes()).toContain('is-valid');

      await submitForm();

      expect(findNameField().classes()).toContain('is-invalid');
    });

    it('shows a warning if permissions are unchecked', async () => {
      expect(findCheckboxes().at(0).find('input').classes()).not.toContain('is-invalid');

      await submitForm();

      expect(findCheckboxes().at(0).find('input').classes()).toContain('is-invalid');
    });
  });

  describe('when create role form is submitted', () => {
    it('disables the submit and cancel buttons', async () => {
      await createComponent();
      await fillForm();
      // Verify that the buttons don't start off as disabled.
      expect(findButtonSubmit().props('loading')).toBe(false);
      expect(findButtonCancel().props('disabled')).toBe(false);

      await submitForm();

      expect(findButtonSubmit().props('loading')).toBe(true);
      expect(findButtonCancel().props('disabled')).toBe(true);
    });

    it('dismisses any previous alert', async () => {
      await createComponent({ mutationMock: jest.fn().mockRejectedValue() });
      await fillForm();
      await submitForm(waitForPromises);

      // Verify that the first alert was created and not dismissed.
      expect(createAlert).toHaveBeenCalledTimes(1);
      expect(mockAlertDismiss).toHaveBeenCalledTimes(0);

      await submitForm(waitForPromises);

      // Verify that the second alert was created and the first was dismissed.
      expect(createAlert).toHaveBeenCalledTimes(2);
      expect(mockAlertDismiss).toHaveBeenCalledTimes(1);
    });

    it.each(['group-path', null])(
      'calls the mutation with the correct data when groupFullPath is %s',
      async (groupFullPath) => {
        await createComponent({ groupFullPath });
        await fillForm();
        await submitForm();

        const input = {
          baseAccessLevel: 'GUEST',
          name: 'My role name',
          description: 'My description',
          permissions: ['A'],
          ...(groupFullPath ? { groupPath: groupFullPath } : {}),
        };

        expect(mutationSuccessHandler).toHaveBeenCalledWith({ input });
      },
    );
  });

  describe('when create role succeeds', () => {
    beforeEach(async () => {
      await createComponent();
      await fillForm();
    });

    it('emits success event', async () => {
      expect(wrapper.emitted('success')).toBeUndefined();

      await submitForm(waitForPromises);

      expect(wrapper.emitted('success')).toHaveLength(1);
    });
  });

  describe('when there is an error creating the role', () => {
    const mutationMock = jest
      .fn()
      .mockResolvedValue({ data: { memberRoleCreate: { errors: ['reason'] } } });

    beforeEach(async () => {
      await createComponent({ mutationMock });
      await fillForm();
    });

    it('shows an error alert', async () => {
      await submitForm(waitForPromises);

      expect(createAlert).toHaveBeenCalledWith({ message: 'Failed to create role: reason' });
    });

    it('enables the submit and cancel buttons', () => {
      expect(findButtonSubmit().props('loading')).toBe(false);
      expect(findButtonCancel().props('disabled')).toBe(false);
    });

    it('does not emit the success event', () => {
      expect(wrapper.emitted('success')).toBeUndefined();
    });
  });

  describe('dependent permissions', () => {
    const checkPermissions = (permissions) => {
      wrapper.findComponent(GlFormCheckboxGroup).vm.$emit('input', permissions);
    };

    const expectCheckedPermissions = (expected) => {
      const selectedValues = wrapper
        .findComponent(GlFormCheckboxGroup)
        .attributes('checked')
        .split(',')
        .sort();

      expect(selectedValues).toEqual(expected.sort());
    };

    beforeEach(() => {
      return createComponent({ stubs: { GlFormCheckboxGroup: true } });
    });

    it.each`
      permission | expected
      ${'A'}     | ${['A']}
      ${'B'}     | ${['A', 'B']}
      ${'C'}     | ${['A', 'B', 'C']}
      ${'D'}     | ${['A', 'B', 'C', 'D']}
      ${'E'}     | ${['E', 'F']}
      ${'F'}     | ${['E', 'F']}
      ${'G'}     | ${['A', 'B', 'C', 'G']}
    `('selects $expected when $permission is selected', async ({ permission, expected }) => {
      await checkPermissions([permission]);

      expectCheckedPermissions(expected);
    });

    it.each`
      permission | expected
      ${'A'}     | ${['E', 'F']}
      ${'B'}     | ${['A', 'E', 'F']}
      ${'C'}     | ${['A', 'B', 'E', 'F']}
      ${'D'}     | ${['A', 'B', 'C', 'E', 'F', 'G']}
      ${'E'}     | ${['A', 'B', 'C', 'D', 'G']}
      ${'F'}     | ${['A', 'B', 'C', 'D', 'G']}
      ${'G'}     | ${['A', 'B', 'C', 'D', 'E', 'F']}
    `(
      'selects $expected when all permissions are selected and $permission is unselected',
      async ({ permission, expected }) => {
        const allPermissions = mockDefaultPermissions.map((p) => p.value);
        const selectedPermissions = allPermissions.filter((v) => v !== permission);
        // Start by checking all the permissions.
        await checkPermissions(allPermissions);
        // Uncheck the permission by removing it from all permissions.
        await checkPermissions(selectedPermissions);

        expectCheckedPermissions(expected);
      },
    );
  });
});

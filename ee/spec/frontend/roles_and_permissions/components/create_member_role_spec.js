import { GlFormInput, GlFormSelect, GlFormTextarea, GlFormCheckbox } from '@gitlab/ui';
import { nextTick } from 'vue';
import { createAlert, VARIANT_DANGER } from '~/alert';
import { createMemberRole } from 'ee/api/member_roles_api';
import CreateMemberRole from 'ee/roles_and_permissions/components/create_member_role.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';

jest.mock('ee/api/member_roles_api');

const mockAlertDismiss = jest.fn();
jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

const DEFAULT_PERMISSIONS = [
  { name: 'Permission A', description: 'Description A', value: 'permission_a' },
  { name: 'Permission B', description: 'Description B', value: 'permission_b' },
  { name: 'Permission C', description: 'Description C', value: 'permission_c' },
];

describe('CreateMemberRole', () => {
  let wrapper;

  const createComponent = ({ availablePermissions = DEFAULT_PERMISSIONS, stubs = {} } = {}) => {
    wrapper = mountExtended(CreateMemberRole, {
      propsData: {
        groupId: '4',
        availablePermissions,
      },
      stubs,
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
    DEFAULT_PERMISSIONS.forEach((permission, index) => {
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

    createComponent({ manageProjectAccessTokens: true, availablePermissions: [permission] });

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

  describe('when successful submission', () => {
    beforeEach(() => {
      createComponent();
      fillForm();
    });

    it('sends the correct data', async () => {
      findButtonSubmit().trigger('submit');
      await waitForPromises();

      expect(createMemberRole).toHaveBeenCalledWith('4', {
        base_access_level: 10,
        name: 'My role name',
        description: 'My description',
        permission_a: 1,
      });
    });

    it('emits success event', async () => {
      expect(wrapper.emitted('success')).toBeUndefined();

      findButtonSubmit().trigger('submit');
      await waitForPromises();

      expect(wrapper.emitted('success')).toHaveLength(1);
    });
  });

  describe('when unsuccessful submission', () => {
    beforeEach(() => {
      createComponent();
      fillForm();

      createMemberRole.mockRejectedValue(new Error());
    });

    it('shows alert', async () => {
      findButtonSubmit().trigger('submit');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to create role.',
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

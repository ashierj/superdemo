import { GlFormInput, GlFormSelect } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import createMemberRoleMutation from 'ee/roles_and_permissions/graphql/create_member_role.mutation.graphql';
import CreateMemberRole from 'ee/roles_and_permissions/components/create_member_role.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import { visitUrl } from '~/lib/utils/url_utility';
import PermissionsSelector from 'ee/roles_and_permissions/components/permissions_selector.vue';

Vue.use(VueApollo);

const mockAlertDismiss = jest.fn();
jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('CreateMemberRole', () => {
  let wrapper;

  const mutationSuccessHandler = jest
    .fn()
    .mockResolvedValue({ data: { memberRoleCreate: { errors: [] } } });

  const createComponent = ({
    stubs,
    mutationMock = mutationSuccessHandler,
    groupFullPath = 'test-group',
    embedded = false,
  } = {}) => {
    wrapper = mountExtended(CreateMemberRole, {
      propsData: { groupFullPath, embedded, listPagePath: 'http://list/page/path' },
      stubs: { PermissionsSelector: true, ...stubs },
      apolloProvider: createMockApollo([[createMemberRoleMutation, mutationMock]]),
    });

    return waitForPromises();
  };

  const findButtonSubmit = () => wrapper.findByTestId('submit-button');
  const findButtonCancel = () => wrapper.findByTestId('cancel-button');
  const findNameField = () => wrapper.findAllComponents(GlFormInput).at(0);
  const findSelect = () => wrapper.findComponent(GlFormSelect);
  const findDescriptionField = () => wrapper.findAllComponents(GlFormInput).at(1);
  const findPermissionsSelector = () => wrapper.findComponent(PermissionsSelector);

  const fillForm = () => {
    findSelect().setValue('GUEST');
    findNameField().setValue('My role name');
    findDescriptionField().setValue('My description');
    findPermissionsSelector().vm.$emit('update:permissions', ['A']);

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
      { value: 'MINIMAL_ACCESS', text: 'Minimal Access' },
      { value: 'GUEST', text: 'Guest' },
      { value: 'REPORTER', text: 'Reporter' },
      { value: 'DEVELOPER', text: 'Developer' },
      { value: 'MAINTAINER', text: 'Maintainer' },
      { value: 'OWNER', text: 'Owner' },
    ]);
  });

  it('navigates back to list page when cancel button is clicked', () => {
    createComponent();

    findButtonCancel().trigger('click');

    expect(visitUrl).toHaveBeenCalledWith('http://list/page/path');
  });

  describe('embedded mode', () => {
    it('emits cancel event when the cancel button is clicked', () => {
      createComponent({ embedded: true });

      expect(wrapper.emitted('cancel')).toBeUndefined();

      findButtonCancel().trigger('click');

      expect(wrapper.emitted('cancel')).toHaveLength(1);
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

    it('shows a warning if no permissions are selected', async () => {
      expect(findPermissionsSelector().props('state')).toBe(true);

      findPermissionsSelector().vm.$emit('update:permissions', []);
      await submitForm();

      expect(findPermissionsSelector().props('state')).toBe(false);
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
    it('redirects to the list page path', async () => {
      await createComponent();
      await fillForm();
      await submitForm(waitForPromises);

      expect(visitUrl).toHaveBeenCalledWith('http://list/page/path');
    });

    describe('embedded mode', () => {
      it('emits success event', async () => {
        await createComponent({ embedded: true });
        await fillForm();

        expect(wrapper.emitted('success')).toBeUndefined();

        await submitForm(waitForPromises);

        expect(wrapper.emitted('success')).toHaveLength(1);
      });
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
});

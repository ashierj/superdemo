import { GlFormCheckbox, GlFormCheckboxGroup, GlSkeletonLoader } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import PermissionsSelector from 'ee/roles_and_permissions/components/permissions_selector.vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import memberRolePermissionsQuery from 'ee/roles_and_permissions/graphql/member_role_permissions.query.graphql';
import { mockPermissions, mockDefaultPermissions } from '../mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('Permissions Selector component', () => {
  let wrapper;

  const defaultAvailablePermissionsHandler = jest.fn().mockResolvedValue(mockPermissions);

  const createComponent = ({
    permissions = [],
    state = true,
    availablePermissionsHandler = defaultAvailablePermissionsHandler,
    mountFn = shallowMountExtended,
  } = {}) => {
    wrapper = mountFn(PermissionsSelector, {
      propsData: { permissions, state },
      apolloProvider: createMockApollo([[memberRolePermissionsQuery, availablePermissionsHandler]]),
    });

    return waitForPromises();
  };

  const findCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findCheckboxGroup = () => wrapper.findComponent(GlFormCheckboxGroup);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  const checkPermissions = (permissions) => {
    findCheckboxGroup().vm.$emit('input', permissions);
  };

  const expectCheckedPermissions = (expected) => {
    const permissions = wrapper.emitted('update:permissions')[0][0];

    expect(permissions.sort()).toEqual(expected.sort());
  };

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

      expect(findCheckboxes()).toHaveLength(0);
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Could not fetch available permissions.',
      });
    });
  });

  describe('dependent permissions', () => {
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
      await createComponent();
      checkPermissions([permission]);

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
      'selects $expected when all permissions start off selected and $permission is unselected',
      async ({ permission, expected }) => {
        const permissions = mockDefaultPermissions.map((p) => p.value);
        const selectedPermissions = permissions.filter((v) => v !== permission);
        await createComponent({ permissions });
        // Uncheck the permission by removing it from all permissions.
        checkPermissions(selectedPermissions);

        expectCheckedPermissions(expected);
      },
    );
  });

  describe('validation state', () => {
    it.each`
      state    | expectedIsInvalid
      ${true}  | ${false}
      ${false} | ${true}
    `('shows validation as $state when state is $state', async ({ state, expectedIsInvalid }) => {
      await createComponent({ state, mountFn: mountExtended });

      const input = findCheckboxes().at(0).find('input');
      // is-valid should always be false, otherwise the text color will be green instead of black.
      expect(input.classes('is-valid')).toBe(false);
      expect(input.classes('is-invalid')).toBe(expectedIsInvalid);
    });
  });
});

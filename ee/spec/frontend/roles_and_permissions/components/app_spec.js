import { shallowMount } from '@vue/test-utils';
import CustomRolesApp from 'ee/roles_and_permissions/components/app.vue';
import CustomRolesEmptyState from 'ee/roles_and_permissions/components/custom_roles_empty_state.vue';

describe('CustomRolesApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(CustomRolesApp);
  };

  const findEmptyState = () => wrapper.findComponent(CustomRolesEmptyState);

  beforeEach(() => {
    createComponent();
  });

  describe('on creation', () => {
    it('renders the empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });
  });
});

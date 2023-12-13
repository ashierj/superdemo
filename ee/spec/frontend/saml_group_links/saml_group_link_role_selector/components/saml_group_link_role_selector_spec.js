import SamlGroupLinkRoleSelector from 'ee/saml_group_links/saml_group_link_role_selector/components/saml_group_link_role_selector.vue';
import RoleSelector from 'ee/roles_and_permissions/components/role_selector.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('SamlGroupLinkRoleSelector', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(SamlGroupLinkRoleSelector);
  };

  const findStandardRoleInputElement = () => wrapper.findByTestId('selected-standard-role').element;
  const findCustomRoleInputElement = () => wrapper.findByTestId('selected-custom-role').element;
  const findSelectedStandardRole = () => findStandardRoleInputElement().value;
  const findSelectedCustomRole = () => findCustomRoleInputElement().value;
  const findRoleSelector = () => wrapper.findComponent(RoleSelector);

  describe('component', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('on mount', () => {
      it('sets the correct initial value', () => {
        expect(findSelectedStandardRole()).toBe('');
        expect(findSelectedCustomRole()).toBe('');
      });
    });

    describe('onSelect event fired', () => {
      it('sets the correct values', async () => {
        const newStandardRoleValue = 20;
        const newCustomRoleValue = 12;

        await findRoleSelector().vm.$emit('onSelect', {
          selectedStandardRoleValue: newStandardRoleValue,
          selectedCustomRoleValue: newCustomRoleValue,
        });

        expect(findSelectedStandardRole()).toBe(newStandardRoleValue.toString());
        expect(findSelectedCustomRole()).toBe(newCustomRoleValue.toString());
      });
    });
  });
});

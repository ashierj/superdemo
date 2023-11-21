import { GlCollapsibleListbox } from '@gitlab/ui';
import SamlMembershipRoleSelector from 'ee/saml_providers/saml_membership_role_selector/components/saml_membership_role_selector.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('SamlMembershipRoleSelector', () => {
  let wrapper;

  const defaultPropsData = {
    standardRoles: [
      { id: 10, text: 'Guest' },
      { id: 30, text: 'Developer' },
    ],
    currentStandardRole: 30,
    customRoles: [{ id: 10, text: 'Custom Role' }],
    currentCustomRoleId: 10,
  };

  const createComponent = (props = {}) => {
    wrapper = mountExtended(SamlMembershipRoleSelector, {
      propsData: {
        ...defaultPropsData,
        ...props,
      },
    });
  };

  const standardDropdownOptions = defaultPropsData.standardRoles.map((role) => ({
    ...role,
    value: `standard-${role.id}`,
  }));
  const customDropdownOptions = defaultPropsData.customRoles.map((role) => ({
    ...role,
    value: `custom-${role.id}`,
  }));

  const findListBox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxItem = (value) => wrapper.findByTestId(`listbox-item-${value}`);
  const selectListboxItem = (value) => findListBox().vm.$emit('select', value);
  const findSelectedStandardRole = () =>
    wrapper.findByTestId('selected-standard-role').element.value;
  const findSelectedCustomRole = () => wrapper.findByTestId('selected-custom-role').element.value;

  describe('dropdown', () => {
    describe('when custom roles are present', () => {
      beforeEach(() => {
        createComponent();
      });

      it('shows the categories', () => {
        expect(findListBox().text()).toContain('Standard roles');
        expect(findListBox().text()).toContain('Custom roles');
      });

      it('shows the standard dropdown items with correct text and value', () => {
        standardDropdownOptions.forEach(({ value, text }) => {
          expect(findListboxItem(value).text()).toBe(text);
        });
      });

      it('shows the custom dropdown items with correct text and value', () => {
        customDropdownOptions.forEach(({ value, text }) => {
          expect(findListboxItem(value).text()).toBe(text);
        });
      });

      it('sets the correct initial value', () => {
        expect(findSelectedStandardRole()).toBe('');
        expect(findSelectedCustomRole()).toBe(defaultPropsData.currentCustomRoleId.toString());
      });
    });

    describe('when the custom roles are missing', () => {
      beforeEach(() => {
        createComponent({ customRoles: [] });
      });

      it('sets the correct initial value to the standard role', () => {
        expect(findSelectedStandardRole()).toBe(defaultPropsData.currentStandardRole.toString());
        expect(findSelectedCustomRole()).toBe('');
      });

      it('does not show categories', () => {
        expect(findListBox().text()).not.toContain('Standard roles');
        expect(findListBox().text()).not.toContain('Custom roles');
      });
    });

    describe('selecting items', () => {
      beforeEach(() => {
        createComponent();
      });

      it('sets the correct values when clicking the standard dropdown items', async () => {
        for await (const { id, value } of standardDropdownOptions) {
          await selectListboxItem(value);

          expect(findSelectedStandardRole()).toBe(id.toString());
          expect(findSelectedCustomRole()).toBe('');
        }
      });

      it('sets the correct values when clicking the custom dropdown items', async () => {
        for await (const { id, value } of customDropdownOptions) {
          await selectListboxItem(value);

          expect(findSelectedStandardRole()).toBe('');
          expect(findSelectedCustomRole()).toBe(id.toString());
        }
      });
    });
  });
});

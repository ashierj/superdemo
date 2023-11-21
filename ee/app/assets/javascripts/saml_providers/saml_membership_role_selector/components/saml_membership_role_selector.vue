<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';

const STANDARD_ROLE = 'standard';
const CUSTOM_ROLE = 'custom';
// GlCollapsibleListbox expects that every item has a unique value even across groups, but the IDs in standard and
// custom roles can overlap. This will construct a unique ID for an item.
const getRoleValue = (roleType, roleId) => `${roleType}-${roleId}`;

export default {
  components: {
    GlCollapsibleListbox,
  },
  props: {
    standardRoles: {
      type: Array,
      required: true,
    },
    currentStandardRole: {
      type: Number,
      required: true,
    },
    customRoles: {
      type: Array,
      required: false,
      default: () => [],
    },
    currentCustomRoleId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      // A passed custom role takes precedence.
      selectedRole: this.customRoles.some(({ id }) => id === this.currentCustomRoleId)
        ? getRoleValue(CUSTOM_ROLE, this.currentCustomRoleId)
        : getRoleValue(STANDARD_ROLE, this.currentStandardRole),
    };
  },
  computed: {
    roles() {
      const mapRoles = (roles, roleType) =>
        roles.map((role) => ({ text: role.text, value: getRoleValue(roleType, role.id) }));

      // If there are no custom roles defined, just display the standard roles without categories.
      if (!this.customRoles.length) {
        return mapRoles(this.standardRoles, STANDARD_ROLE);
      }

      return [
        {
          text: this.$options.i18n.standardRolesCategoryText,
          options: mapRoles(this.standardRoles, STANDARD_ROLE),
        },
        {
          text: this.$options.i18n.customRolesCategoryText,
          options: mapRoles(this.customRoles, CUSTOM_ROLE),
        },
      ];
    },
    selectedStandardRoleValue() {
      return this.getRoleId(STANDARD_ROLE);
    },
    selectedCustomRoleValue() {
      return this.getRoleId(CUSTOM_ROLE);
    },
  },
  watch: {
    async selectedRole() {
      // This is necessary for `DirtySubmitForm` to detect changes in the form and toggle the submit button.
      await this.$nextTick();
      const event = new Event('input', { bubbles: true });

      this.$refs.standardRoleInput.dispatchEvent(event);
      this.$refs.customRoleInput.dispatchEvent(event);
    },
  },
  methods: {
    getRoleId(roleType) {
      const [type, id] = this.selectedRole.split('-');
      return type === roleType ? id : null;
    },
  },
  i18n: {
    standardRolesCategoryText: s__('GroupSAML|Standard roles'),
    customRolesCategoryText: s__('GroupSAML|Custom roles'),
  },
};
</script>

<template>
  <div>
    <input
      ref="standardRoleInput"
      data-testid="selected-standard-role"
      type="hidden"
      name="saml_provider[default_membership_role]"
      :value="selectedStandardRoleValue"
    />
    <input
      ref="customRoleInput"
      data-testid="selected-custom-role"
      type="hidden"
      name="saml_provider[member_role_id]"
      :value="selectedCustomRoleValue"
    />
    <gl-collapsible-listbox
      v-model="selectedRole"
      block
      data-testid="default-membership-role-dropdown"
      :items="roles"
    />
  </div>
</template>

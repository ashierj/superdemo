<script>
import RoleSelector from 'ee/roles_and_permissions/components/role_selector.vue';

export default {
  components: {
    RoleSelector,
  },
  data() {
    return {
      selectedStandardRoleValue: null,
      selectedCustomRoleValue: null,
    };
  },
  methods: {
    onSelect({ selectedStandardRoleValue, selectedCustomRoleValue }) {
      this.selectedStandardRoleValue = selectedStandardRoleValue;
      this.selectedCustomRoleValue = selectedCustomRoleValue;
    },
  },
};
</script>

<template>
  <div>
    <input
      data-testid="selected-standard-role"
      type="hidden"
      name="saml_group_link[access_level]"
      :value="selectedStandardRoleValue"
    />
    <input
      data-testid="selected-custom-role"
      type="hidden"
      name="saml_group_link[member_role_id]"
      :value="selectedCustomRoleValue"
    />
    <role-selector @onSelect="onSelect" />
  </div>
</template>

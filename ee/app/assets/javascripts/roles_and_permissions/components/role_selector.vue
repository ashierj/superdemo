<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { initialSelectedRole, roleDropdownItems } from 'ee/members/utils';

export default {
  components: {
    GlCollapsibleListbox,
  },
  inject: {
    standardRoles: {
      type: Object,
      required: true,
    },
    currentStandardRole: {
      type: Number,
      required: false,
      default: null,
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
      selectedRole: null,
      accessLevelOptions: roleDropdownItems({
        validRoles: this.standardRoles,
        customRoles: this.customRoles,
      }),
    };
  },
  watch: {
    accessLevelOptions: {
      immediate: true,
      handler(options) {
        const accessLevel = {
          integerValue: this.currentStandardRole,
          memberRoleId: this.currentCustomRoleId,
        };
        this.selectedRole = initialSelectedRole(options.flatten, { accessLevel });
      },
    },
  },
  methods: {
    onSelect() {
      const { accessLevel, memberRoleId } = this.accessLevelOptions.flatten.find(
        (item) => item.value === this.selectedRole,
      );

      this.$emit('onSelect', {
        selectedStandardRoleValue: accessLevel,
        selectedCustomRoleValue: memberRoleId,
      });
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    v-model="selectedRole"
    block
    :items="accessLevelOptions.formatted"
    @select="onSelect"
  />
</template>

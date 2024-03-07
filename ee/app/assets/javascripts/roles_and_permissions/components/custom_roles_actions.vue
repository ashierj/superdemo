<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'CustomRolesActions',
  i18n: {
    actionsText: s__('MemberRole|Actions'),
    editRoleText: s__('MemberRole|Edit role'),
    deleteRoleText: s__('MemberRole|Delete role'),
  },
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  computed: {
    editRoleItem() {
      return {
        text: this.$options.i18n.editRoleText,
      };
    },
    deleteRoleItem() {
      return {
        text: this.$options.i18n.deleteRoleText,
        extraAttrs: {
          class: 'gl-text-red-500!',
        },
      };
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    v-gl-tooltip.hover.top.viewport="$options.i18n.actionsText"
    category="tertiary"
    icon="ellipsis_v"
    placement="right"
    no-caret
  >
    <gl-disclosure-dropdown-item :item="editRoleItem" />
    <gl-disclosure-dropdown-item :item="deleteRoleItem" />
  </gl-disclosure-dropdown>
</template>

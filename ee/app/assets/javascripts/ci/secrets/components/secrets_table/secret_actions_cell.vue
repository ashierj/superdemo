<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';

export default {
  name: 'SecretActionsCell',
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
  },
  props: {
    detailsRoute: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    icon="ellipsis_v"
    toggle-text="Actions"
    text-sr-only
    category="tertiary"
    no-caret
  >
    <gl-disclosure-dropdown-item>
      <template #list-item>
        <router-link
          data-testid="secret-details-link"
          :to="detailsRoute"
          class="gl-display-block gl-text-body gl-hover-text-gray-900 gl-hover-text-decoration-none"
        >
          {{ s__('Secrets|Edit secret') }}
        </router-link>
      </template>
    </gl-disclosure-dropdown-item>
    <gl-disclosure-dropdown-item>
      <template #list-item>
        {{ s__('Secrets|Delete') }}
      </template>
    </gl-disclosure-dropdown-item>
    <gl-disclosure-dropdown-item>
      <template #list-item>
        {{ s__('Secrets|Revoke') }}
      </template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown>
</template>

<script>
import { GlButtonGroup, GlButton, GlCollapsibleListbox, GlIcon, GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';

export default {
  components: {
    GlButtonGroup,
    GlButton,
    GlCollapsibleListbox,
    GlIcon,
    GlBadge,
  },
  props: {
    buttons: {
      type: Array,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      selectedButtonIndex: 0,
    };
  },
  computed: {
    selectedButton() {
      return this.buttons[this.selectedButtonIndex];
    },
    items() {
      return this.buttons.map((button, index) => ({ ...button, value: index }));
    },
  },
  methods: {
    handleClick() {
      if (this.selectedButton.href) {
        visitUrl(this.selectedButton.href, true);
      } else {
        this.$emit(this.selectedButton.action);
      }
    },
  },
  i18n: {
    changeAction: __('Change action'),
  },
};
</script>

<template>
  <!--TODO: Replace button-group workaround once `split` option for new dropdowns is implemented.-->
  <!-- See issue at https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2263-->
  <gl-button-group v-if="selectedButton">
    <gl-button
      :disabled="disabled"
      variant="confirm"
      :href="selectedButton.href"
      :icon="selectedButton.icon"
      :loading="selectedButton.loading"
      @click="handleClick"
    >
      {{ selectedButton.name }}
      <gl-badge v-if="selectedButton.badge" class="gl-ml-1" size="sm" variant="info">
        {{ selectedButton.badge }}
      </gl-badge>
    </gl-button>
    <gl-collapsible-listbox
      v-model="selectedButtonIndex"
      class="split"
      toggle-class="gl-rounded-top-left-none! gl-rounded-bottom-left-none! gl-pl-1!"
      variant="confirm"
      text-sr-only
      :toggle-text="$options.i18n.changeAction"
      :disabled="disabled || selectedButton.loading"
      :items="items"
    >
      <template #list-item="{ item }">
        <div :data-testid="`${item.action}-button`">
          <strong>
            <gl-icon v-if="item.icon" data-testid="item-icon" :name="item.icon" class="gl-mr-2" />
            {{ item.name }}
          </strong>
          <p class="gl-m-0">
            {{ item.tagline }}
            <gl-badge v-if="item.badge" variant="info" size="sm">{{ item.badge }}</gl-badge>
          </p>
        </div>
      </template>
    </gl-collapsible-listbox>
  </gl-button-group>
</template>

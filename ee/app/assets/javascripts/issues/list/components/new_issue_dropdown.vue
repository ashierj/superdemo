<script>
import { GlButtonGroup, GlButton, GlDisclosureDropdown } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { sprintfWorkItem } from '~/work_items/constants';

export default {
  i18n: {
    newIssueLabel: __('New issue'),
    toggleSrText: __('Issue type'),
  },
  components: {
    GlDisclosureDropdown,
    GlButton,
    GlButtonGroup,
  },
  inject: ['newIssuePath'],
  props: {
    workItemType: {
      type: String,
      required: true,
    },
  },
  computed: {
    items() {
      return [
        {
          text: this.$options.i18n.newIssueLabel,
          href: this.newIssuePath,
        },
        {
          text: sprintfWorkItem(s__('WorkItem|New %{workItemType}'), this.workItemType),
          action: () => this.$emit('select-new-work-item'),
        },
      ];
    },
  },
};
</script>

<template>
  <gl-button-group class="gl-w-full">
    <gl-button variant="confirm" :href="newIssuePath">
      {{ $options.i18n.newIssueLabel }}
    </gl-button>
    <gl-disclosure-dropdown
      :toggle-text="$options.i18n.toggleSrText"
      placement="right"
      text-sr-only
      variant="confirm"
      :items="items"
    />
  </gl-button-group>
</template>

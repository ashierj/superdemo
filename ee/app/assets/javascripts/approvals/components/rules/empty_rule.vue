<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { __ } from '~/locale';
import RuleInput from './rule_input.vue';
import EmptyRuleName from './empty_rule_name.vue';
import RuleBranches from './rule_branches.vue';

export default {
  components: {
    RuleInput,
    EmptyRuleName,
    RuleBranches,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    addApprovalRule: __('Add approval rule'),
  },
  props: {
    rule: {
      type: Object,
      required: true,
    },
    allowMultiRule: {
      type: Boolean,
      required: true,
    },
    eligibleApproversDocsPath: {
      type: String,
      required: false,
      default: '',
    },
    isMrEdit: {
      type: Boolean,
      default: true,
      required: false,
    },
    canEdit: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    showProtectedBranch() {
      return !this.isMrEdit && this.allowMultiRule;
    },
  },
  methods: {
    ...mapActions({ openCreateModal: 'createModal/open' }),
  },
};
</script>

<template>
  <tr>
    <td colspan="2" :data-label="__('Rule')">
      <empty-rule-name :eligible-approvers-docs-path="eligibleApproversDocsPath" />
    </td>
    <td v-if="showProtectedBranch" class="gl-text-center" :data-label="__('Target branch')">
      <rule-branches :rule="rule" />
    </td>
    <td class="gl-py-5! js-approvals-required" :data-label="__('Approvals required')">
      <rule-input :rule="rule" :is-mr-edit="isMrEdit" />
    </td>
    <td class="gl-md-pl-0! gl-md-pr-0!" :data-label="__('Actions')">
      <div class="gl-my-n3! gl-px-5 gl-text-right">
        <gl-button
          v-if="!allowMultiRule && canEdit"
          v-gl-tooltip
          :title="$options.i18n.addApprovalRule"
          :aria-label="$options.i18n.addApprovalRule"
          category="tertiary"
          icon="plus"
          data-testid="add-approval-rule"
          @click="openCreateModal(null)"
        />
      </div>
    </td>
  </tr>
</template>

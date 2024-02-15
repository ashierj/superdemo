<script>
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import RuleName from 'ee/approvals/components/rules/rule_name.vue';
import { n__, sprintf } from '~/locale';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { RULE_TYPE_ANY_APPROVER, RULE_TYPE_REGULAR } from 'ee/approvals/constants';

import EmptyRule from 'ee/approvals/components/rules/empty_rule.vue';
import RuleInput from 'ee/approvals/components/rules/rule_input.vue';
import RuleBranches from 'ee/approvals/components/rules/rule_branches.vue';
import RuleControls from 'ee/approvals/components/rules/rule_controls.vue';
import Rules from 'ee/approvals/components/rules/rules.vue';
import UnconfiguredSecurityRules from 'ee/approvals/components/security_configuration/unconfigured_security_rules.vue';

export default {
  components: {
    RuleControls,
    Rules,
    UserAvatarList,
    EmptyRule,
    RuleInput,
    RuleBranches,
    RuleName,
    UnconfiguredSecurityRules,
  },
  // TODO: Remove feature flag in https://gitlab.com/gitlab-org/gitlab/-/issues/235114
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapState(['settings']),
    ...mapState({
      rules: (state) => state.approvals.rules,
    }),
    hasNamedRule() {
      return this.rules.some((rule) => rule.ruleType === RULE_TYPE_REGULAR);
    },
    firstColumnSpan() {
      return this.hasNamedRule ? '1' : '2';
    },
    firstColumnWidth() {
      return this.hasNamedRule ? 'gl-w-half' : 'gl-w-full';
    },
    hasAnyRule() {
      return (
        this.settings.allowMultiRule &&
        !this.rules.some((rule) => rule.ruleType === RULE_TYPE_ANY_APPROVER)
      );
    },
  },
  watch: {
    rules: {
      handler(newValue) {
        if (
          this.settings.allowMultiRule &&
          !newValue.some((rule) => rule.ruleType === RULE_TYPE_ANY_APPROVER)
        ) {
          this.addEmptyRule();
        }
      },
      immediate: true,
    },
  },
  methods: {
    ...mapActions(['addEmptyRule']),
    summaryText(rule) {
      return this.settings.allowMultiRule
        ? this.summaryMultipleRulesText(rule)
        : this.summarySingleRuleText(rule);
    },
    membersCountText(rule) {
      return n__(
        'ApprovalRuleSummary|%d member',
        'ApprovalRuleSummary|%d members',
        rule.approvers.length,
      );
    },
    summarySingleRuleText(rule) {
      const membersCount = this.membersCountText(rule);

      return sprintf(
        n__(
          'ApprovalRuleSummary|%{count} approval required from %{membersCount}',
          'ApprovalRuleSummary|%{count} approvals required from %{membersCount}',
          rule.approvalsRequired,
        ),
        { membersCount, count: rule.approvalsRequired },
      );
    },
    summaryMultipleRulesText(rule) {
      return sprintf(
        n__(
          '%{count} approval required from %{name}',
          '%{count} approvals required from %{name}',
          rule.approvalsRequired,
        ),
        { name: rule.name, count: rule.approvalsRequired },
      );
    },
    canEdit(rule) {
      const { canEdit, allowMultiRule } = this.settings;

      return canEdit && (!allowMultiRule || !rule.hasSource);
    },
  },
};
</script>

<template>
  <div>
    <rules :rules="rules">
      <template #thead="{ name, members, approvalsRequired, branches, actions }">
        <tr class="d-none d-sm-table-row">
          <th :colspan="firstColumnSpan" :class="firstColumnWidth">
            {{ hasNamedRule ? name : members }}
          </th>
          <th v-if="hasNamedRule" class="gl-w-half d-none d-sm-table-cell">
            <span>{{ members }}</span>
          </th>
          <th v-if="settings.allowMultiRule" class="gl-text-center">{{ branches }}</th>
          <th class="gl-text-center">{{ approvalsRequired }}</th>
          <th>{{ actions }}</th>
        </tr>
      </template>
      <template #tbody="{ rules }">
        <template v-for="(rule, index) in rules">
          <empty-rule
            v-if="rule.ruleType === 'any_approver'"
            :key="index"
            :rule="rule"
            :allow-multi-rule="settings.allowMultiRule"
            :is-mr-edit="false"
            :eligible-approvers-docs-path="settings.eligibleApproversDocsPath"
            :can-edit="canEdit(rule)"
          />
          <tr v-else :key="index">
            <td class="js-name" :data-label="__('Rule')">
              <rule-name :name="rule.name" />
            </td>
            <td class="gl-py-5! js-members" :data-label="__('Approvers')">
              <user-avatar-list
                :items="rule.eligibleApprovers"
                :img-size="24"
                empty-text=""
                class="gl-my-n2!"
              />
            </td>
            <td
              v-if="settings.allowMultiRule"
              class="js-branches gl-text-center"
              :data-label="__('Target branch')"
            >
              <rule-branches :rule="rule" />
            </td>
            <td class="gl-py-5! js-approvals-required" :data-label="__('Approvals required')">
              <rule-input :rule="rule" />
            </td>
            <td class="text-nowrap js-controls gl-md-pl-0! gl-md-pr-0!" :data-label="__('Actions')">
              <rule-controls v-if="canEdit(rule)" :rule="rule" />
            </td>
          </tr>
        </template>
      </template>
    </rules>

    <unconfigured-security-rules />
  </div>
</template>

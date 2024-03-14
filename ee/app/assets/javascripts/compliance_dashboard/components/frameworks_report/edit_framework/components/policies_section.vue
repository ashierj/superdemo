<script>
import { GlBadge, GlFormCheckbox, GlTable, GlTooltipDirective } from '@gitlab/ui';

import { sprintf } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { i18n } from '../constants';
import complianceFrameworkPoliciesQuery from '../graphql/compliance_frameworks_policies.query.graphql';

import EditSection from './edit_section.vue';

function extractPolicies(policies) {
  return {
    policies: policies.nodes,
    hasNextPage: policies.pageInfo.hasNextPage,
    endCursor: policies.pageInfo.endCursor,
  };
}

export default {
  components: {
    EditSection,

    GlBadge,
    GlFormCheckbox,
    GlTable,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },

  props: {
    fullPath: {
      type: String,
      required: true,
    },
    graphqlId: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      rawPolicies: {
        globalApprovalPolicies: [],
        globalScanExecutionPolicies: [],
        approvalPolicies: [],
        scanExecutionPolicies: [],
      },
      policiesLoaded: false,
      policiesLoadCursor: {
        approvalPoliciesGlobalAfter: null,
        scanExecutionPoliciesGlobalAfter: null,
        approvalPoliciesAfter: null,
        scanExecutionPoliciesAfter: null,
      },
    };
  },
  apollo: {
    rawGroupPolicies: {
      query: complianceFrameworkPoliciesQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          complianceFramework: this.graphqlId,
          ...this.policiesLoadCursor,
        };
      },
      update(data) {
        const {
          policies: pendingGlobalApprovalPolicies,
          hasNextPage: hasNextGlobalApprovalPolicies,
          endCursor: approvalPoliciesGlobalAfter,
        } = extractPolicies(data.namespace.approvalPolicies);
        const {
          policies: pendingGlobalScanExecutionPolicies,
          hasNextPage: hasNextGlobalScanExecutionPolicies,
          endCursor: scanExecutionPoliciesGlobalAfter,
        } = extractPolicies(data.namespace.scanExecutionPolicies);
        const {
          policies: pendingApprovalPolicies,
          hasNextPage: hasNextApprovalPolicies,
          endCursor: approvalPoliciesAfter,
        } = extractPolicies(data.namespace.complianceFrameworks.nodes[0].scanResultPolicies);
        const {
          policies: pendingScanExecutionPolicies,
          hasNextPage: hasNextScanExecutionPolicies,
          endCursor: scanExecutionPoliciesAfter,
        } = extractPolicies(data.namespace.complianceFrameworks.nodes[0].scanExecutionPolicies);

        this.policiesLoaded =
          !hasNextGlobalApprovalPolicies &&
          !hasNextGlobalScanExecutionPolicies &&
          !hasNextApprovalPolicies &&
          !hasNextScanExecutionPolicies;

        const newCursor = {
          approvalPoliciesGlobalAfter,
          scanExecutionPoliciesGlobalAfter,
          approvalPoliciesAfter,
          scanExecutionPoliciesAfter,
        };

        [
          'approvalPoliciesGlobalAfter',
          'scanExecutionPoliciesGlobalAfter',
          'approvalPoliciesAfter',
          'scanExecutionPoliciesAfter',
        ].forEach((cursorField) => {
          if (newCursor[cursorField]) {
            this.policiesLoadCursor[cursorField] = newCursor[cursorField];
          }
        });

        this.rawPolicies.approvalPolicies.push(...pendingApprovalPolicies);
        this.rawPolicies.scanExecutionPolicies.push(...pendingScanExecutionPolicies);
        this.rawPolicies.globalApprovalPolicies.push(...pendingGlobalApprovalPolicies);
        this.rawPolicies.globalScanExecutionPolicies.push(...pendingGlobalScanExecutionPolicies);
      },
      error(error) {
        this.errorMessage = this.$options.i18n.fetchError;
        Sentry.captureException(error);
      },
      skip() {
        return this.policiesLoaded;
      },
    },
  },

  computed: {
    policies() {
      const approvalPoliciesSet = new Set(this.rawPolicies.approvalPolicies.map((p) => p.name));
      const scanExecutionPoliciesSet = new Set(
        this.rawPolicies.scanExecutionPolicies.map((p) => p.name),
      );

      return [
        ...this.rawPolicies.globalApprovalPolicies.map((p) => ({
          ...p,
          isLinked: approvalPoliciesSet.has(p.name),
        })),
        ...this.rawPolicies.globalScanExecutionPolicies.map((p) => ({
          ...p,
          isLinked: scanExecutionPoliciesSet.has(p.name),
        })),
      ].sort((a, b) => (a.name > b.name ? 1 : -1));
    },

    description() {
      if (!this.policiesLoaded) {
        // zero-width-space to avoid jump
        return '\u200b';
      }

      const { length: count } = this.policies;
      const { length: linkedCount } = this.policies.filter((p) => p.isLinked);

      return [
        sprintf(i18n.policiesLinkedCount(linkedCount), { count: linkedCount }),
        sprintf(i18n.policiesTotalCount(count), { count }),
      ].join(' ');
    },
  },
  methods: {
    getTooltip(policy) {
      return policy.isLinked ? i18n.policiesLinkedTooltip : i18n.policiesUnlinkedTooltip;
    },
  },

  tableFields: [
    {
      key: 'linked',
      label: i18n.policiesTableFields.linked,
      thClass: 'gl-white-space-nowrap gl-w-5p',
      tdClass: 'gl-text-center',
    },
    {
      key: 'name',
      label: i18n.policiesTableFields.name,
    },
    {
      key: 'description',
      label: i18n.policiesTableFields.desc,
    },
  ],
  i18n,
};
</script>
<template>
  <edit-section :title="$options.i18n.policies" :description="description" expandable>
    <gl-table
      :items="policies"
      :fields="$options.tableFields"
      :busy="$apollo.queries.rawGroupPolicies.loading"
      responsive
      stacked="md"
    >
      <template #cell(linked)="{ item }">
        <div v-gl-tooltip="getTooltip(item)" class="gl-w-5 gl-display-inline-block">
          <gl-form-checkbox :checked="item.isLinked" disabled />
        </div>
      </template>
      <template #cell(name)="{ item }">
        {{ item.name }}
        <div v-if="!item.enabled">
          <gl-badge variant="muted" size="sm">
            {{ __('Disabled') }}
          </gl-badge>
        </div>
      </template>
    </gl-table>
  </edit-section>
</template>

<script>
import {
  GlAvatarLabeled,
  GlAvatarLink,
  GlBadge,
  GlSkeletonLoader,
  GlTable,
  GlTooltipDirective,
  GlKeysetPagination,
} from '@gitlab/ui';
import { pick } from 'lodash';
import { s__ } from '~/locale';
import { ADD_ON_ERROR_DICTIONARY } from 'ee/usage_quotas/error_constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { addOnEligibleUserListTableFields } from 'ee/usage_quotas/code_suggestions/constants';
import ErrorAlert from 'ee/vue_shared/components/error_alert/error_alert.vue';
import { scrollToElement } from '~/lib/utils/common_utils';
import CodeSuggestionsAddonAssignment from 'ee/usage_quotas/code_suggestions/components/code_suggestions_addon_assignment.vue';

export default {
  name: 'AddOnEligibleUserList',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CodeSuggestionsAddonAssignment,
    ErrorAlert,
    GlAvatarLabeled,
    GlAvatarLink,
    GlBadge,
    GlKeysetPagination,
    GlSkeletonLoader,
    GlTable,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    addOnPurchaseId: {
      type: String,
      required: true,
    },
    users: {
      type: Array,
      required: false,
      default: () => [],
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    pageInfo: {
      type: Object,
      required: false,
      default: () => {},
    },
    search: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      addOnAssignmentError: undefined,
    };
  },
  addOnErrorDictionary: ADD_ON_ERROR_DICTIONARY,
  avatarSize: 32,
  computed: {
    hasMaxRoleField() {
      return this.tableItems?.some(({ maxRole }) => maxRole);
    },
    isFilteringEnabled() {
      return this.glFeatures.enableAddOnUsersFiltering;
    },
    showPagination() {
      if (this.isLoading || !this.pageInfo) {
        return false;
      }
      const { hasNextPage, hasPreviousPage } = this.pageInfo;
      return hasNextPage || hasPreviousPage;
    },
    emptyText() {
      if (this.search?.length < 3) {
        return s__('Billing|Enter at least three characters to search.');
      }
      return s__('Billing|No users to display.');
    },
    tableFieldsConfiguration() {
      if (this.isFilteringEnabled && this.hasMaxRoleField) {
        return ['user', 'codeSuggestionsAddon', 'email', 'maxRole', 'lastActivityTime'];
      }
      return ['user', 'codeSuggestionsAddon', 'emailWide', 'lastActivityTimeWide'];
    },
    tableFields() {
      return Object.values(pick(addOnEligibleUserListTableFields, this.tableFieldsConfiguration));
    },
    tableItems() {
      return this.users.map((node) => ({
        ...node,
        username: `@${node?.username}`,
        addOnAssignments: node?.addOnAssignments?.nodes,
      }));
    },
  },
  methods: {
    nextPage() {
      this.$emit('next', this.pageInfo.endCursor);
    },
    prevPage() {
      this.$emit('prev', this.pageInfo.startCursor);
    },
    handleAddOnAssignmentError(errorCode) {
      this.addOnAssignmentError = errorCode;
      this.scrollToTop();
    },
    clearAddOnAssignmentError() {
      this.addOnAssignmentError = undefined;
    },
    scrollToTop() {
      scrollToElement(this.$el);
    },
  },
};
</script>

<template>
  <section>
    <slot name="search-and-sort-bar"> </slot>
    <slot name="error-alert"></slot>
    <error-alert
      v-if="addOnAssignmentError"
      data-testid="add-on-assignment-error"
      :error="addOnAssignmentError"
      :error-dictionary="$options.addOnErrorDictionary"
      :dismissible="true"
      @dismiss="clearAddOnAssignmentError"
    />
    <gl-table
      :items="tableItems"
      :fields="tableFields"
      :busy="isLoading"
      :show-empty="true"
      :empty-text="emptyText"
      primary-key="id"
      data-testid="add-on-eligible-users-table"
    >
      <template #table-busy>
        <div class="gl-ml-n4 gl-pt-3">
          <gl-skeleton-loader>
            <rect x="0" y="0" width="60" height="3" rx="1" />
            <rect x="126" y="0" width="60" height="3" rx="1" />
            <rect x="207" y="0" width="60" height="3" rx="1" />
            <rect x="338" y="0" width="60" height="3" rx="1" />
          </gl-skeleton-loader>
        </div>
      </template>
      <template #cell(user)="{ item }">
        <slot name="user-cell" :item="item">
          <div class="gl-display-flex">
            <gl-avatar-link target="_blank" :href="item.webUrl" :alt="item.name">
              <gl-avatar-labeled
                :src="item.avatarUrl"
                :size="$options.avatarSize"
                :label="item.name"
                :sub-label="item.username"
              />
            </gl-avatar-link>
          </div>
        </slot>
      </template>
      <template #cell(email)="{ item }">
        <div data-testid="email">
          <span v-if="item.publicEmail" class="gl-text-gray-900">{{ item.publicEmail }}</span>
          <span
            v-else
            v-gl-tooltip
            :title="s__('Billing|An email address is only visible for users with public emails.')"
            class="gl-font-style-italic"
          >
            {{ s__('Billing|Private') }}
          </span>
        </div>
      </template>
      <template #cell(codeSuggestionsAddon)="{ item }">
        <code-suggestions-addon-assignment
          :user-id="item.id"
          :add-on-assignments="item.addOnAssignments"
          :add-on-purchase-id="addOnPurchaseId"
          @handleAddOnAssignmentError="handleAddOnAssignmentError"
          @clearAddOnAssignmentError="clearAddOnAssignmentError"
        />
      </template>
      <template #cell(maxRole)="{ item }">
        <gl-badge v-if="item.maxRole" data-testid="max-role">{{ item.maxRole }}</gl-badge>
      </template>
      <template #cell(lastActivityTime)="data">
        <span data-testid="last-activity-on">
          {{ data.item.lastActivityOn ? data.item.lastActivityOn : __('Never') }}
        </span>
      </template>
    </gl-table>
    <div v-if="showPagination" class="gl-display-flex gl-justify-content-center gl-mt-5">
      <gl-keyset-pagination v-bind="pageInfo" @prev="prevPage" @next="nextPage" />
    </div>
  </section>
</template>

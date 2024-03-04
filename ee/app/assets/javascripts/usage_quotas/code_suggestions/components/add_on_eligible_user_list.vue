<script>
import {
  GlAvatarLabeled,
  GlAvatarLink,
  GlBadge,
  GlButton,
  GlFormCheckbox,
  GlSkeletonLoader,
  GlTable,
  GlTooltipDirective,
  GlKeysetPagination,
} from '@gitlab/ui';
import { pick, escape } from 'lodash';
import { s__, n__, sprintf } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { ADD_ON_ERROR_DICTIONARY } from 'ee/usage_quotas/error_constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  addOnEligibleUserListTableFields,
  ASSIGN_SEATS_BULK_ACTION,
  UNASSIGN_SEATS_BULK_ACTION,
} from 'ee/usage_quotas/code_suggestions/constants';
import ErrorAlert from 'ee/vue_shared/components/error_alert/error_alert.vue';
import { scrollToElement } from '~/lib/utils/common_utils';
import CodeSuggestionsAddonAssignment from 'ee/usage_quotas/code_suggestions/components/code_suggestions_addon_assignment.vue';
import AddOnBulkActionConfirmationModal from 'ee/usage_quotas/code_suggestions/components/add_on_bulk_action_confirmation_modal.vue';

export default {
  name: 'AddOnEligibleUserList',
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  components: {
    AddOnBulkActionConfirmationModal,
    CodeSuggestionsAddonAssignment,
    ErrorAlert,
    GlAvatarLabeled,
    GlAvatarLink,
    GlBadge,
    GlButton,
    GlFormCheckbox,
    GlKeysetPagination,
    GlSkeletonLoader,
    GlTable,
  },
  mixins: [glFeatureFlagMixin()],
  inject: { isBulkAddOnAssignmentEnabled: { default: false } },
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
      selectedUsers: [],
      bulkAction: undefined,
      isConfirmationModalVisible: false,
    };
  },
  addOnErrorDictionary: ADD_ON_ERROR_DICTIONARY,
  assignSeatsBulkAction: ASSIGN_SEATS_BULK_ACTION,
  unassignSeatsBulkAction: UNASSIGN_SEATS_BULK_ACTION,
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
      let fieldConfig = ['user', 'codeSuggestionsAddon', 'emailWide', 'lastActivityTimeWide'];

      if (this.isFilteringEnabled && this.hasMaxRoleField) {
        fieldConfig = ['user', 'codeSuggestionsAddon', 'email', 'maxRole', 'lastActivityTime'];
      }

      if (this.isBulkAddOnAssignmentEnabled) {
        fieldConfig = ['checkbox', ...fieldConfig];
      }

      return fieldConfig;
    },
    tableFields() {
      return Object.values(pick(addOnEligibleUserListTableFields, this.tableFieldsConfiguration));
    },
    tableItems() {
      return this.users.map((node) => ({
        ...node,
        usernameWithHandle: `@${node?.username}`,
        addOnAssignments: node?.addOnAssignments?.nodes,
      }));
    },
    isSelectAllUsersChecked() {
      return !this.isLoading && this.users.length === this.selectedUsers.length;
    },
    isSelectAllUsersIndeterminate() {
      return this.isAnyUserSelected && !this.isSelectAllUsersChecked;
    },
    isAnyUserSelected() {
      return Boolean(this.selectedUsers.length);
    },
    pluralisedSelectedUsers() {
      return sprintf(
        n__(
          'Billing|%{value} user selected',
          'Billing|%{value} users selected',
          this.selectedUsers.length,
        ),
        { value: `<strong>${escape(this.selectedUsers.length)}</strong>` },
        false,
      );
    },
  },
  methods: {
    nextPage() {
      // Retaining user selection on page navigation will be carried out in
      // https://gitlab.com/gitlab-org/gitlab/-/issues/443401
      this.unselectAllUsers();
      this.$emit('next', this.pageInfo.endCursor);
    },
    prevPage() {
      // Retaining user selection on page navigation will be carried out in
      // https://gitlab.com/gitlab-org/gitlab/-/issues/443401
      this.unselectAllUsers();
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
    isUserSelected(item) {
      return this.selectedUsers.includes(item.username);
    },
    handleUserSelection(user, value) {
      if (value) {
        this.selectedUsers.push(user.username);
      } else {
        this.selectedUsers = this.selectedUsers.filter((username) => username !== user.username);
      }
    },
    handleSelectAllUsers(value) {
      if (value) {
        this.selectedUsers = this.users.map((user) => user.username);
      } else {
        this.unselectAllUsers();
      }
    },
    unselectAllUsers() {
      this.selectedUsers = [];
    },
    showConfirmationModal(bulkAction) {
      this.isConfirmationModalVisible = true;
      this.bulkAction = bulkAction;
    },
    handleCancelBulkAction() {
      this.isConfirmationModalVisible = false;
      this.bulkAction = undefined;
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
    <div
      v-if="isAnyUserSelected"
      class="gl-display-flex gl-bg-gray-10 gl-p-5 gl-mt-5 gl-align-items-center gl-justify-content-space-between"
    >
      <span v-safe-html="pluralisedSelectedUsers" data-testid="selected-users-summary"></span>
      <div class="gl-display-flex gl-gap-3">
        <gl-button
          data-testid="unassign-seats-button"
          variant="danger"
          category="secondary"
          @click="showConfirmationModal($options.unassignSeatsBulkAction)"
          >{{ s__('Billing|Remove seat') }}</gl-button
        >
        <gl-button
          data-testid="assign-seats-button"
          variant="confirm"
          category="primary"
          @click="showConfirmationModal($options.assignSeatsBulkAction)"
          >{{ s__('Billing|Assign seat') }}</gl-button
        >
      </div>
    </div>
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
      <template #head(checkbox)>
        <gl-form-checkbox
          v-if="isBulkAddOnAssignmentEnabled"
          class="gl-min-h-5"
          :checked="isSelectAllUsersChecked"
          :indeterminate="isSelectAllUsersIndeterminate"
          data-testid="select-all-users"
          @change="handleSelectAllUsers"
        />
      </template>
      <template #cell(checkbox)="{ item }">
        <gl-form-checkbox
          v-if="isBulkAddOnAssignmentEnabled"
          class="gl-min-h-5"
          :checked="isUserSelected(item)"
          @change="handleUserSelection(item, $event)"
        />
      </template>
      <template #cell(user)="{ item }">
        <slot name="user-cell" :item="item">
          <div class="gl-display-flex">
            <gl-avatar-link target="_blank" :href="item.webUrl" :alt="item.name">
              <gl-avatar-labeled
                :src="item.avatarUrl"
                :size="$options.avatarSize"
                :label="item.name"
                :sub-label="item.usernameWithHandle"
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

    <add-on-bulk-action-confirmation-modal
      v-if="isConfirmationModalVisible"
      :bulk-action="bulkAction"
      :user-count="selectedUsers.length"
      @cancel="handleCancelBulkAction"
    />
  </section>
</template>

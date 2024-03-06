<script>
import {
  GlBadge,
  GlButton,
  GlCard,
  GlEmptyState,
  GlModal,
  GlTable,
  GlLoadingIcon,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { sprintf, s__, __ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ACCESS_LEVEL_LABELS } from '~/access_level/constants';
import groupMemberRolesQuery from 'ee/invite_members/graphql/queries/group_member_roles.query.graphql';
import instanceMemberRolesQuery from '../graphql/instance_member_roles.query.graphql';
import deleteMemberRoleMutation from '../graphql/delete_member_role.mutation.graphql';
import CreateMemberRole from './create_member_role.vue';

export const FIELDS = [
  { key: 'name', label: s__('MemberRole|Name'), sortable: true },
  { key: 'id', label: s__('MemberRole|ID'), sortable: true },
  { key: 'baseAccessLevel', label: s__('MemberRole|Base role'), sortable: true },
  { key: 'permissions', label: s__('MemberRole|Permissions') },
  { key: 'actions', label: s__('MemberRole|Actions') },
];

export default {
  i18n: {
    addNewRole: s__('MemberRole|Add new role'),
    cardTitle: s__('MemberRole|Custom roles'),
    deleteRole: s__('MemberRole|Delete role'),
    cancel: __('Cancel'),
    deleteModalTitle: s__('MemberRole|Are you sure you want to delete this role?'),
    deleteModalWarning: s__(
      'MemberRole|To delete the custom role make sure no group member has this custom role',
    ),
    emptyTitle: s__('MemberRole|No custom roles found'),
    emptyDescription: s__(`MemberRole|To add a new role select 'Add new role'.`),
    fetchRolesError: s__('MemberRole|Failed to fetch roles.'),
    deleteSuccess: s__('MemberRole|Role successfully deleted.'),
    deleteError: s__('MemberRole|Failed to delete role.'),
    deleteErrorWithReason: s__('MemberRole|Failed to delete role. %{error}'),
    createSuccess: s__('MemberRole|Role successfully created.'),
  },
  components: {
    CreateMemberRole,
    GlBadge,
    GlButton,
    GlCard,
    GlEmptyState,
    GlModal,
    GlTable,
    GlLoadingIcon,
  },
  props: {
    groupFullPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      alert: null,
      isDeletingRole: false,
      isDeleteRoleModalVisible: false,
      memberRoles: [],
      memberRoleToDelete: null,
      showCreateMemberForm: false,
      availablePermissions: [],
    };
  },
  apollo: {
    memberRoles: {
      query() {
        return this.fetchMemberRolesQuery;
      },
      variables() {
        return { fullPath: this.groupFullPath };
      },
      update(data) {
        const nodes = this.groupFullPath
          ? data?.namespace?.memberRoles?.nodes
          : data?.memberRoles?.nodes;

        const memberRoles = nodes || [];

        return memberRoles.map(({ id, name, baseAccessLevel, enabledPermissions }) => ({
          id,
          name,
          baseAccessLevel: ACCESS_LEVEL_LABELS[baseAccessLevel.integerValue],
          permissions: enabledPermissions.nodes,
        }));
      },
      error() {
        this.alert = createAlert({ message: this.$options.i18n.fetchRolesError });
      },
    },
  },
  computed: {
    fetchMemberRolesQuery() {
      return this.groupFullPath ? groupMemberRolesQuery : instanceMemberRolesQuery;
    },
    isLoading() {
      return this.$apollo.queries.memberRoles.loading || this.isDeletingRole;
    },
    modalActions() {
      return {
        primary: {
          text: this.$options.i18n.deleteRole,
          attributes: { variant: 'danger' },
        },
        cancel: {
          text: this.$options.i18n.cancel,
        },
      };
    },
  },
  methods: {
    async deleteMemberRole() {
      // Dismiss any existing alerts.
      this.alert?.dismiss();
      this.isDeletingRole = true;

      try {
        const response = await this.$apollo.mutate({
          mutation: deleteMemberRoleMutation,
          variables: { input: { id: this.memberRoleToDelete } },
        });
        const error = response.data.memberRoleDelete.errors[0];

        if (error) {
          this.alert = createAlert({
            message: sprintf(this.$options.i18n.deleteErrorWithReason, { error }),
          });
        } else {
          this.$toast.show(this.$options.i18n.deleteSuccess);
          this.refetchRoles();
        }
      } catch ({ message }) {
        this.alert = createAlert({ message: this.$options.i18n.deleteError });
      } finally {
        this.memberRoleToDelete = null;
        this.isDeletingRole = false;
      }
    },
    refetchRoles() {
      this.$apollo.queries.memberRoles.refetch();
    },
    onCreatedMemberRole() {
      this.$toast.show(this.$options.i18n.createSuccess);
      this.showCreateMemberForm = false;
      this.refetchRoles();
    },
    showDeleteModal(id) {
      this.memberRoleToDelete = id;
      this.isDeleteRoleModalVisible = true;
    },
  },
  FIELDS,
  getIdFromGraphQLId,
};
</script>

<template>
  <gl-card
    header-class="gl-new-card-header"
    body-class="gl-new-card-body gl-px-0 gl-bg-gray-10"
    class="gl-mt-5"
  >
    <template #header>
      <div class="gl-new-card-title-wrapper">
        <h3 class="gl-new-card-title" data-testid="card-title">
          {{ $options.i18n.cardTitle }}
          <span class="gl-new-card-count" data-testid="counter">{{ memberRoles.length }}</span>
        </h3>
      </div>
      <div class="gl-new-card-actions">
        <gl-button
          :loading="isLoading"
          size="small"
          data-testid="add-role"
          @click="showCreateMemberForm = true"
        >
          {{ $options.i18n.addNewRole }}
        </gl-button>
      </div>
    </template>

    <div v-if="showCreateMemberForm" class="gl-new-card-add-form gl-m-3">
      <create-member-role
        :group-full-path="groupFullPath"
        :available-permissions="availablePermissions"
        @cancel="showCreateMemberForm = false"
        @success="onCreatedMemberRole"
      />
    </div>

    <gl-empty-state
      v-if="memberRoles.length === 0 && !showCreateMemberForm"
      :title="$options.i18n.emptyTitle"
      :description="$options.i18n.emptyDescription"
    />

    <gl-table
      v-else-if="memberRoles.length || !showCreateMemberForm"
      :fields="$options.FIELDS"
      :items="memberRoles"
      :busy="isLoading"
      stacked="sm"
    >
      <template #table-busy>
        <gl-loading-icon size="lg" />
      </template>
      <template #cell(id)="{ item }">
        {{ $options.getIdFromGraphQLId(item.id) }}
      </template>
      <template #cell(baseAccessLevel)="{ item: { baseAccessLevel } }">
        <gl-badge class="gl-my-n4">{{ baseAccessLevel }}</gl-badge>
      </template>

      <template #cell(permissions)="{ item: { permissions } }">
        <div
          class="gl-display-flex gl-flex-wrap gl-gap-3 gl-justify-content-end gl-sm-justify-content-start"
        >
          <gl-badge
            v-for="(permission, index) in permissions"
            :key="index"
            variant="success"
            size="sm"
          >
            {{ permission.name }}
          </gl-badge>
        </div>
      </template>

      <template #cell(actions)="{ item: { id } }">
        <gl-button
          class="gl-my-n4"
          category="tertiary"
          :aria-label="$options.i18n.deleteRole"
          icon="remove"
          data-testid="delete-role-button"
          @click="showDeleteModal(id)"
        />
      </template>
    </gl-table>

    <gl-modal
      v-model="isDeleteRoleModalVisible"
      modal-id="confirm-delete-role"
      size="sm"
      :title="$options.i18n.deleteModalTitle"
      :action-primary="modalActions.primary"
      :action-secondary="modalActions.cancel"
      @primary="deleteMemberRole"
    >
      <p>{{ $options.i18n.deleteModalWarning }}</p>
    </gl-modal>
  </gl-card>
</template>

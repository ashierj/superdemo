<script>
import { GlBadge, GlButton, GlCard, GlEmptyState, GlModal, GlTable } from '@gitlab/ui';
import { capitalize } from 'lodash';
import { createAlert } from '~/alert';
import { sprintf, s__, __ } from '~/locale';
import { TYPENAME_MEMBER_ROLE } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import groupMemberRolesQuery from 'ee/invite_members/graphql/queries/group_member_roles.query.graphql';
import instanceMemberRolesQuery from '../graphql/instance_member_roles.query.graphql';
import memberRolePermissionsQuery from '../graphql/member_role_permissions.query.graphql';
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
    emptyTitle: s__('MemberRole|No custom roles found'),
    emptyDescription: s__(`MemberRole|To add a new role select 'Add new role'.`),
    fetchRolesError: s__('MemberRole|Failed to fetch roles: %{message}'),
    fetchPermissionsError: s__('MemberRole|Could not fetch available permissions: %{message}'),
    deleteSuccess: s__('MemberRole|Role successfully deleted.'),
    deleteError: s__('MemberRole|Failed to delete role.'),
    deleteErrorWithReason: s__('MemberRole|Failed to delete role. %{message}'),
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
        return {
          fullPath: this.groupFullPath,
        };
      },
      update(data) {
        const nodes = this.groupFullPath
          ? data?.namespace?.memberRoles?.nodes
          : data?.memberRoles?.nodes;

        const memberRoles = nodes || [];

        return memberRoles.map(({ id, name, baseAccessLevel, enabledPermissions }) => ({
          name,
          id: getIdFromGraphQLId(id),
          baseAccessLevel: capitalize(baseAccessLevel.stringValue),
          permissions: enabledPermissions.nodes,
        }));
      },
      error({ message }) {
        this.alert = createAlert({
          message: sprintf(this.$options.i18n.fetchRolesError, { message }),
        });
      },
    },
    availablePermissions: {
      query: memberRolePermissionsQuery,
      update(data) {
        return data?.memberRolePermissions?.nodes || [];
      },
      error({ message }) {
        this.alert = createAlert({
          message: sprintf(this.$options.i18n.fetchPermissionsError, { message }),
        });
      },
    },
  },
  computed: {
    fetchMemberRolesQuery() {
      return this.groupFullPath ? groupMemberRolesQuery : instanceMemberRolesQuery;
    },
    isLoading() {
      return (
        this.$apollo.queries.memberRoles.loading ||
        this.$apollo.queries.availablePermissions.loading
      );
    },
    isModalVisible() {
      return this.memberRoleToDelete !== null;
    },
  },
  methods: {
    async deleteMemberRole() {
      this.alert?.dismiss();

      this.$apollo
        .mutate({
          mutation: deleteMemberRoleMutation,
          refetchQueries: [this.fetchMemberRolesQuery],
          variables: {
            input: {
              id: convertToGraphQLId(TYPENAME_MEMBER_ROLE, this.memberRoleToDelete),
            },
          },
          update: (_, result) => {
            const { errors } = result.data.memberRoleDelete;

            if (errors?.length) {
              const errorMessage = sprintf(this.$options.i18n.deleteErrorWithReason, {
                message: errors.join('. '),
              });
              createAlert({ message: errorMessage });
            } else {
              this.$toast.show(this.$options.i18n.deleteSuccess);
            }
          },
        })
        .catch(() => {
          this.alert = createAlert({
            message: this.$options.i18n.deleteError,
          });
        })
        .finally(() => {
          this.memberRoleToDelete = null;
        });
    },
    onCreatedMemberRole() {
      this.$toast.show(this.$options.i18n.createSuccess);
      this.showCreateMemberForm = false;
    },
    onModalHide() {
      this.memberRoleToDelete = null;
    },
    showConfirm(memberRoleId) {
      this.memberRoleToDelete = `${memberRoleId}`;
    },
  },
  FIELDS,
  modal: {
    actionPrimary: {
      text: s__('MemberRole|Delete role'),
      attributes: {
        variant: 'danger',
      },
    },
    actionSecondary: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
    id: 'confirm-delete-role',
    title: s__('MemberRole|Are you sure you want to delete this role?'),
    warning: s__(
      'MemberRole|To delete the custom role make sure no group member has this custom role',
    ),
  },
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

    <gl-table v-else :fields="$options.FIELDS" :items="memberRoles" :busy="isLoading" stacked="sm">
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
          @click="showConfirm(id)"
        />
      </template>
    </gl-table>

    <gl-modal
      :visible="isModalVisible"
      :modal-id="$options.modal.id"
      size="sm"
      :title="$options.modal.title"
      :action-primary="$options.modal.actionPrimary"
      :action-secondary="$options.modal.actionSecondary"
      @primary="deleteMemberRole"
      @hide="onModalHide"
    >
      <p>{{ $options.modal.warning }}</p>
    </gl-modal>
  </gl-card>
</template>

<script>
import { GlBadge, GlButton, GlCard, GlEmptyState, GlModal, GlTable } from '@gitlab/ui';
import { keyBy } from 'lodash';
import { deleteMemberRole, getMemberRoles } from 'ee/rest_api';
import { ACCESS_LEVEL_LABELS } from '~/access_level/constants';
import { createAlert } from '~/alert';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import { sprintf, s__, __ } from '~/locale';
import memberRolePermissionsQuery from '../graphql/member_role_permissions.query.graphql';
import CreateMemberRole from './create_member_role.vue';

export const FIELDS = [
  { key: 'name', label: s__('MemberRole|Name'), sortable: true },
  { key: 'id', label: s__('MemberRole|ID'), sortable: true },
  { key: 'base_access_level', label: s__('MemberRole|Base role'), sortable: true },
  { key: 'permissions', label: s__('MemberRole|Permissions') },
  { key: 'actions', label: s__('MemberRole|Actions') },
];

export default {
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
    emptyText: {
      type: String,
      required: false,
      default: null,
    },
    groupId: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      alert: null,
      isLoadingMemberRoles: false,
      memberRoles: [],
      memberRoleToDelete: null,
      showCreateMemberForm: false,
      availablePermissions: [],
    };
  },
  apollo: {
    availablePermissions: {
      query: memberRolePermissionsQuery,
      update({ memberRolePermissions }) {
        return memberRolePermissions.nodes;
      },
      error({ message }) {
        this.alert = createAlert({
          message: sprintf(this.$options.i18n.fetchPermissionsError, { message }),
        });
      },
    },
  },
  computed: {
    isModalVisible() {
      return this.memberRoleToDelete !== null;
    },
    availablePermissionsLookup() {
      return keyBy(this.availablePermissions, 'value');
    },
  },
  watch: {
    groupId: function newFetch(newGroupId) {
      this.fetchMemberRoles(newGroupId);
    },
  },
  created() {
    this.fetchMemberRoles(this.groupId);
  },
  methods: {
    async deleteMemberRole() {
      this.alert?.dismiss();

      try {
        await deleteMemberRole(this.groupId, this.memberRoleToDelete);
        this.$toast.show(this.$options.i18n.deleteSuccess);
        this.fetchMemberRoles(this.groupId);
      } catch (error) {
        this.alert = createAlert({
          message: error.response?.data?.message || this.$options.i18n.deleteError,
        });
      } finally {
        this.memberRoleToDelete = null;
      }
    },
    async fetchMemberRoles(groupId) {
      this.alert?.dismiss();

      if (!groupId) {
        this.memberRoles = [];
        return;
      }
      this.isLoadingMemberRoles = true;

      try {
        const { data } = await getMemberRoles(groupId);
        this.memberRoles = data;
      } catch (error) {
        this.memberRoles = [];
        if (error?.response?.status === HTTP_STATUS_NOT_FOUND) {
          this.alert = createAlert({ message: this.$options.i18n.licenseError });
        } else {
          this.alert = createAlert({
            message: error?.response?.data?.message || this.$options.i18n.fetchRolesError,
          });
        }
      } finally {
        this.isLoadingMemberRoles = false;
      }
    },
    listPermissions(item) {
      return Object.entries(item).reduce((array, [key, value]) => {
        const permission = this.availablePermissionsLookup[key.toUpperCase()];
        // The member roles data has a mix of permissions data and other data. Only add the permission's name if the key
        // is a permission and if its value is true.
        if (permission && value) {
          array.push(permission.name);
        }

        return array;
      }, []);
    },
    nameAccessLevel(value) {
      return ACCESS_LEVEL_LABELS[value];
    },
    onCreatedMemberRole() {
      this.$toast.show(this.$options.i18n.createSuccess);
      this.showCreateMemberForm = false;
      this.fetchMemberRoles(this.groupId);
    },
    onModalHide() {
      this.memberRoleToDelete = null;
    },
    showConfirm(memberRoleId) {
      this.memberRoleToDelete = `${memberRoleId}`;
    },
  },
  FIELDS,
  i18n: {
    addNewRole: s__('MemberRole|Add new role'),
    cardTitle: s__('MemberRole|Custom roles'),
    deleteRole: s__('MemberRole|Delete role'),
    emptyTitle: s__('MemberRole|No custom roles for this group'),
    fetchRolesError: s__('MemberRole|Failed to fetch roles.'),
    fetchPermissionsError: s__('MemberRole|Could not fetch available permissions: %{message}'),
    deleteSuccess: s__('MemberRole|Role successfully deleted.'),
    deleteError: s__('MemberRole|Failed to delete the role.'),
    createSuccess: s__('MemberRole|Role successfully created.'),
    licenseError: s__('MemberRole|Make sure the group is in the Ultimate tier.'),
  },
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
  <gl-card header-class="gl-new-card-header" body-class="gl-new-card-body gl-px-0 gl-bg-gray-10">
    <template #header>
      <div class="gl-new-card-title-wrapper">
        <h3 class="gl-new-card-title" data-testid="card-title">
          {{ $options.i18n.cardTitle }}
          <span class="gl-new-card-count" data-testid="counter">{{ memberRoles.length }}</span>
        </h3>
      </div>
      <div class="gl-new-card-actions">
        <gl-button
          :disabled="!groupId"
          :loading="$apollo.queries.availablePermissions.loading"
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
        :group-id="groupId"
        :available-permissions="availablePermissions"
        @cancel="showCreateMemberForm = false"
        @success="onCreatedMemberRole"
      />
    </div>

    <gl-empty-state
      v-if="memberRoles.length === 0 && !showCreateMemberForm"
      :title="$options.i18n.emptyTitle"
      :description="emptyText"
    />

    <gl-table
      v-else
      :fields="$options.FIELDS"
      :items="memberRoles"
      :busy="isLoadingMemberRoles || $apollo.queries.availablePermissions.loading"
      stacked="sm"
    >
      <template #cell(base_access_level)="{ item: { base_access_level } }">
        <gl-badge class="gl-my-n4">{{ nameAccessLevel(base_access_level) }}</gl-badge>
      </template>

      <template #cell(permissions)="{ item }">
        <div
          class="gl-display-flex gl-flex-wrap gl-gap-3 gl-justify-content-end gl-sm-justify-content-start"
        >
          <gl-badge
            v-for="(permission, index) in listPermissions(item)"
            :key="index"
            variant="success"
            size="sm"
          >
            {{ permission }}
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

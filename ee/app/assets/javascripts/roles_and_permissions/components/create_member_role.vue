<script>
import {
  GlButton,
  GlForm,
  GlFormCheckbox,
  GlFormCheckboxGroup,
  GlFormGroup,
  GlFormInput,
  GlFormSelect,
  GlFormTextarea,
  GlSkeletonLoader,
} from '@gitlab/ui';
import { difference, pull } from 'lodash';
import { createAlert } from '~/alert';
import { sprintf, s__, __ } from '~/locale';
import { BASE_ROLES } from '~/access_level/constants';
import memberRolePermissionsQuery from 'ee/roles_and_permissions/graphql/member_role_permissions.query.graphql';
import createMemberRoleMutation from '../graphql/create_member_role.mutation.graphql';

export default {
  i18n: {
    createError: s__('MemberRole|Failed to create role.'),
    createErrorWithReason: s__('MemberRole|Failed to create role: %{error}'),
    permissionsFetchError: s__('MemberRole|Could not fetch available permissions.'),
    createNewRole: s__('MemberRole|Create new role'),
    cancel: __('Cancel'),
    baseRoleLabel: s__('MemberRole|Base role to use as template'),
    baseRoleDescription: s__('MemberRole|Select a standard role to add permissions.'),
    nameLabel: s__('MemberRole|Role name'),
    nameDescription: s__('MemberRole|Enter a short name.'),
    namePlaceholder: s__('MemberRole|Incident manager'),
    descriptionLabel: s__('MemberRole|Description'),
    permissionsLabel: s__('MemberRole|Permissions'),
    invalidFeedback: __('This field is required.'),
  },
  components: {
    GlButton,
    GlForm,
    GlFormCheckboxGroup,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlFormTextarea,
    GlSkeletonLoader,
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
      baseRole: null,
      baseRoleValid: true,
      description: '',
      name: '',
      nameValid: true,
      permissions: [],
      permissionsValid: true,
      isSubmitting: false,
      availablePermissions: [],
    };
  },
  apollo: {
    availablePermissions: {
      query: memberRolePermissionsQuery,
      update(data) {
        return data.memberRolePermissions?.nodes || [];
      },
      error() {
        this.alert = createAlert({ message: this.$options.i18n.permissionsFetchError });
      },
    },
  },
  computed: {
    isLoadingPermissions() {
      return this.$apollo.queries.availablePermissions.loading;
    },
    permissionsState() {
      return this.permissionsValid ? null : false;
    },
    parentPermissionsLookup() {
      return this.availablePermissions.reduce((acc, { value, requirements }) => {
        if (requirements) {
          acc[value] = requirements;
        }

        return acc;
      }, {});
    },
    childPermissionsLookup() {
      return this.availablePermissions.reduce((acc, { value, requirements }) => {
        requirements?.forEach((requirement) => {
          // Create the array if it doesn't exist, then add the requirement to it.
          acc[requirement] = acc[requirement] || [];
          acc[requirement].push(value);
        });

        return acc;
      }, {});
    },
  },
  watch: {
    permissions(newPermissions, oldPermissions) {
      const added = difference(newPermissions, oldPermissions);
      const removed = difference(oldPermissions, newPermissions);

      added.forEach((permission) => this.selectParentPermissions(permission));
      removed.forEach((permission) => this.deselectChildPermissions(permission));
    },
  },
  methods: {
    selectParentPermissions(permission) {
      const parentPermissions = this.parentPermissionsLookup[permission];

      parentPermissions?.forEach((parentPermission) => {
        // Only select the parent permission if it's not already selected.
        if (!this.permissions.includes(parentPermission)) {
          this.permissions.push(parentPermission);
          this.selectParentPermissions(parentPermission);
        }
      });
    },
    deselectChildPermissions(permission) {
      const childPermissions = this.childPermissionsLookup[permission];

      childPermissions?.forEach((childPermission) => {
        // Only remove the child permission if it's selected.
        if (this.permissions.includes(childPermission)) {
          pull(this.permissions, childPermission);
          this.deselectChildPermissions(childPermission);
        }
      });
    },
    validateFields() {
      this.baseRoleValid = this.baseRole !== null;
      this.nameValid = Boolean(this.name);
      this.permissionsValid = this.permissions.length > 0;

      return this.baseRoleValid && this.nameValid && this.permissionsValid;
    },
    async createMemberRole() {
      this.alert?.dismiss();

      if (!this.validateFields()) {
        return;
      }

      this.isSubmitting = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: createMemberRoleMutation,
          variables: {
            input: {
              baseAccessLevel: this.baseRole,
              name: this.name,
              description: this.description,
              permissions: this.permissions,
              ...(this.groupFullPath ? { groupPath: this.groupFullPath } : {}),
            },
          },
        });

        const error = data.memberRoleCreate.errors[0];
        if (error) {
          this.alert = createAlert({
            message: sprintf(this.$options.i18n.createErrorWithReason, { error }, false),
          });
        } else {
          this.$emit('success');
        }
      } catch {
        this.alert = createAlert({ message: sprintf(this.$options.i18n.createError) });
      } finally {
        this.isSubmitting = false;
      }
    },
  },
  BASE_ROLES,
};
</script>

<template>
  <gl-form @submit.prevent="createMemberRole">
    <h4 class="gl-mt-0">{{ $options.i18n.createNewRole }}</h4>
    <div class="row">
      <gl-form-group
        class="col-md-4"
        :label="$options.i18n.baseRoleLabel"
        :description="$options.i18n.baseRoleDescription"
        :invalid-feedback="$options.i18n.invalidFeedback"
        label-for="base-role-select"
      >
        <gl-form-select
          id="base-role-select"
          v-model.number="baseRole"
          :options="$options.BASE_ROLES"
          :state="baseRoleValid"
        />
      </gl-form-group>

      <gl-form-group
        class="col-md-4"
        :label="$options.i18n.nameLabel"
        :description="$options.i18n.nameDescription"
        :invalid-feedback="$options.i18n.invalidFeedback"
        label-for="role-name"
      >
        <gl-form-input
          id="role-name"
          v-model.trim="name"
          :placeholder="$options.i18n.namePlaceholder"
          :state="nameValid"
        />
      </gl-form-group>

      <gl-form-group class="col-lg-8" :label="$options.i18n.descriptionLabel">
        <gl-form-textarea v-model="description" />
      </gl-form-group>
    </div>

    <gl-form-group :label="$options.i18n.permissionsLabel">
      <gl-skeleton-loader v-if="isLoadingPermissions" />
      <gl-form-checkbox-group v-model="permissions" :state="permissionsState">
        <gl-form-checkbox
          v-for="permission in availablePermissions"
          :key="permission.value"
          :value="permission.value"
          :data-testid="permission.value"
        >
          {{ permission.name }}
          <template v-if="permission.description" #help>
            {{ permission.description }}
          </template>
        </gl-form-checkbox>
      </gl-form-checkbox-group>
    </gl-form-group>

    <div class="gl-display-flex gl-flex-wrap gl-gap-3">
      <gl-button
        type="submit"
        :loading="isSubmitting"
        data-testid="submit-button"
        variant="confirm"
        class="js-no-auto-disable"
      >
        {{ $options.i18n.createNewRole }}
      </gl-button>
      <gl-button
        type="reset"
        data-testid="cancel-button"
        :disabled="isSubmitting"
        @click="$emit('cancel')"
      >
        {{ $options.i18n.cancel }}
      </gl-button>
    </div>
  </gl-form>
</template>

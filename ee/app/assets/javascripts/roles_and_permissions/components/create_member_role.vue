<script>
import {
  GlButton,
  GlForm,
  GlFormCheckbox,
  GlFormCheckboxGroup,
  GlFormGroup,
  GlFormInput,
  GlFormSelect,
  GlSkeletonLoader,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import { difference, pull } from 'lodash';
import { createAlert } from '~/alert';
import { sprintf, s__, __ } from '~/locale';
import { BASE_ROLES } from '~/access_level/constants';
import memberRolePermissionsQuery from 'ee/roles_and_permissions/graphql/member_role_permissions.query.graphql';
import { visitUrl } from '~/lib/utils/url_utility';
import { helpPagePath } from '~/helpers/help_page_helper';
import createMemberRoleMutation from '../graphql/create_member_role.mutation.graphql';

export default {
  i18n: {
    createError: s__('MemberRole|Failed to create role.'),
    createErrorWithReason: s__('MemberRole|Failed to create role: %{error}'),
    permissionsFetchError: s__('MemberRole|Could not fetch available permissions.'),
    createRole: s__('MemberRole|Create role'),
    cancel: __('Cancel'),
    baseRoleLabel: s__('MemberRole|Base role'),
    baseRoleDescription: s__(
      'MemberRole|Select a %{linkStart}pre-existing static role%{linkEnd} to predefine a set of permissions.',
    ),
    nameLabel: s__('MemberRole|Name'),
    descriptionLabel: s__('MemberRole|Description'),
    descriptionDescription: s__(
      'MemberRole|Example: "Developer with admin and read access to vulnerability"',
    ),
    permissionsLabel: s__('MemberRole|Permissions'),
    customPermissionsLabel: s__('MemberRole|Custom permissions'),
    customPermissionsDescription: s__(
      'MemberRole|Add at least one custom permission to the base role.',
    ),
    invalidFeedback: __('This field is required.'),
    validationError: s__('MemberRole|You must fill out all required fields.'),
  },
  components: {
    GlButton,
    GlForm,
    GlFormCheckboxGroup,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlSkeletonLoader,
    GlSprintf,
    GlLink,
  },
  props: {
    groupFullPath: {
      type: String,
      required: false,
      default: null,
    },
    listPagePath: {
      type: String,
      required: false,
      default: '',
    },
    embedded: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      alert: null,
      baseRole: null,
      baseRoleValid: true,
      description: '',
      descriptionValid: true,
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
    staticRolesHelpPagePath() {
      return helpPagePath('user/permissions', { anchor: 'roles' });
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
      this.nameValid = this.name.length > 0;
      this.descriptionValid = this.description.length > 0;
      this.baseRoleValid = this.baseRole !== null;
      this.permissionsValid = this.permissions.length > 0;

      return this.nameValid && this.descriptionValid && this.baseRoleValid && this.permissionsValid;
    },
    async createMemberRole() {
      this.alert?.dismiss();

      if (!this.validateFields()) {
        this.alert = createAlert({ message: this.$options.i18n.validationError });
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
        } else if (this.embedded) {
          this.$emit('success');
        } else {
          visitUrl(this.listPagePath);
        }
      } catch {
        this.alert = createAlert({ message: this.$options.i18n.createError });
      } finally {
        this.isSubmitting = false;
      }
    },
    handleCancelClick() {
      if (this.embedded) {
        this.$emit('cancel');
      } else {
        visitUrl(this.listPagePath);
      }
    },
  },
  BASE_ROLES,
};
</script>

<template>
  <gl-form @submit.prevent="createMemberRole">
    <h4 v-if="embedded" class="gl-mt-0">{{ $options.i18n.createRole }}</h4>
    <h2 v-else class="gl-mb-6">{{ $options.i18n.createRole }}</h2>

    <gl-form-group
      :label="$options.i18n.nameLabel"
      label-for="role-name"
      :invalid-feedback="$options.i18n.invalidFeedback"
    >
      <gl-form-input
        id="role-name"
        v-model.trim="name"
        :state="nameValid"
        width="xl"
        maxlength="255"
      />
    </gl-form-group>

    <gl-form-group
      :label="$options.i18n.descriptionLabel"
      :invalid-feedback="$options.i18n.invalidFeedback"
      :description="$options.i18n.descriptionDescription"
      label-for="description"
    >
      <gl-form-input
        id="description"
        v-model.trim="description"
        :state="descriptionValid"
        width="xl"
        maxlength="255"
      />
    </gl-form-group>

    <h4 v-if="embedded" class="gl-mt-7">{{ $options.i18n.permissionsLabel }}</h4>
    <h3 v-else class="gl-mt-8 gl-mb-6">{{ $options.i18n.permissionsLabel }}</h3>

    <gl-form-group
      :label="$options.i18n.baseRoleLabel"
      :invalid-feedback="$options.i18n.invalidFeedback"
      label-for="base-role-select"
      label-class="gl-pb-1!"
      class="gl-mb-6"
    >
      <template #label-description>
        <div class="gl-mb-3">
          <gl-sprintf :message="$options.i18n.baseRoleDescription">
            <template #link="{ content }">
              <gl-link :href="staticRolesHelpPagePath">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </div>
      </template>
      <gl-form-select
        id="base-role-select"
        v-model="baseRole"
        width="md"
        :options="$options.BASE_ROLES"
        :state="baseRoleValid"
      />
    </gl-form-group>

    <gl-form-group :label="$options.i18n.customPermissionsLabel" label-class="gl-pb-1!">
      <template #label-description>
        <div v-if="!isLoadingPermissions" class="gl-mb-6">
          {{ $options.i18n.customPermissionsDescription }}
        </div>
      </template>

      <div v-if="isLoadingPermissions" class="gl-mt-5">
        <gl-skeleton-loader />
      </div>

      <gl-form-checkbox-group v-else v-model="permissions" :state="permissionsState">
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
        {{ $options.i18n.createRole }}
      </gl-button>
      <gl-button
        type="reset"
        data-testid="cancel-button"
        :disabled="isSubmitting"
        @click="handleCancelClick"
      >
        {{ $options.i18n.cancel }}
      </gl-button>
    </div>
  </gl-form>
</template>

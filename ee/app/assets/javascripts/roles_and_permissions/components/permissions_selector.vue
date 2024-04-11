<script>
import { GlFormCheckbox, GlFormCheckboxGroup, GlFormGroup, GlSkeletonLoader } from '@gitlab/ui';
import { difference, pull } from 'lodash';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import memberRolePermissionsQuery from 'ee/roles_and_permissions/graphql/member_role_permissions.query.graphql';

export default {
  i18n: {
    customPermissionsLabel: s__('MemberRole|Custom permissions'),
    customPermissionsDescription: s__(
      'MemberRole|Add at least one custom permission to the base role.',
    ),
    permissionsFetchError: s__('MemberRole|Could not fetch available permissions.'),
  },
  components: {
    GlFormCheckboxGroup,
    GlFormCheckbox,
    GlFormGroup,
    GlSkeletonLoader,
  },
  props: {
    permissions: {
      type: Array,
      required: true,
    },
    state: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
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
        createAlert({ message: this.$options.i18n.permissionsFetchError });
      },
    },
  },
  computed: {
    isLoadingPermissions() {
      return this.$apollo.queries.availablePermissions.loading;
    },
    permissionsState() {
      return this.state ? null : false;
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
  methods: {
    emitSelectedPermissions(selected) {
      const added = difference(selected, this.permissions);
      const removed = difference(this.permissions, selected);
      // Check/uncheck any dependent permissions based on what permissions are selected.
      added.forEach((permission) => this.selectParentPermissions(permission, selected));
      removed.forEach((permission) => this.deselectChildPermissions(permission, selected));

      this.$emit('update:permissions', selected);
    },
    selectParentPermissions(permission, selected) {
      const parentPermissions = this.parentPermissionsLookup[permission];

      parentPermissions?.forEach((parent) => {
        // Only select the parent permission if it's not already selected.
        if (!selected.includes(parent)) {
          selected.push(parent);
          this.selectParentPermissions(parent, selected);
        }
      });
    },
    deselectChildPermissions(permission, selected) {
      const childPermissions = this.childPermissionsLookup[permission];

      childPermissions?.forEach((child) => {
        // Only remove the child permission if it's selected.
        if (selected.includes(child)) {
          pull(selected, child);
          this.deselectChildPermissions(child, selected);
        }
      });
    },
  },
};
</script>

<template>
  <gl-form-group :label="$options.i18n.customPermissionsLabel" label-class="gl-pb-1!">
    <template #label-description>
      <div v-if="!isLoadingPermissions" class="gl-mb-6">
        {{ $options.i18n.customPermissionsDescription }}
      </div>
    </template>

    <div v-if="isLoadingPermissions" class="gl-mt-5">
      <gl-skeleton-loader />
    </div>

    <gl-form-checkbox-group
      v-else
      :checked="permissions"
      :state="permissionsState"
      @input="emitSelectedPermissions"
    >
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
</template>

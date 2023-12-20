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
} from '@gitlab/ui';
import { createMemberRole } from 'ee/rest_api';
import { createAlert } from '~/alert';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__ } from '~/locale';
import { ACCESS_LEVEL_GUEST_INTEGER, ACCESS_LEVEL_LABELS } from '~/access_level/constants';

// Base roles with Guest access or higher.
export const BASE_ROLES = Object.entries(ACCESS_LEVEL_LABELS)
  .filter(([value]) => value >= ACCESS_LEVEL_GUEST_INTEGER)
  .map(([value, text]) => ({ value, text }));

export default {
  components: {
    GlButton,
    GlForm,
    GlFormCheckboxGroup,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlFormTextarea,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    groupId: {
      type: String,
      required: true,
    },
    availablePermissions: {
      type: Array,
      required: true,
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
    };
  },
  computed: {
    selectablePermissions() {
      return this.availablePermissions.filter(({ value }) => {
        switch (value) {
          case 'MANAGE_PROJECT_ACCESS_TOKENS':
            return this.glFeatures.manageProjectAccessTokens;
          default:
            return true;
        }
      });
    },
  },
  methods: {
    validateFields() {
      this.baseRoleValid = this.baseRole !== null;
      this.nameValid = Boolean(this.name);
      this.permissionsValid = this.permissions.length > 0;

      return this.baseRoleValid && this.nameValid && this.permissionsValid;
    },
    cancel() {
      this.$emit('cancel');
    },
    async createMemberRole() {
      this.alert?.dismiss();

      if (!this.validateFields()) {
        return;
      }

      const data = {
        base_access_level: this.baseRole,
        name: this.name,
        description: this.description,
      };
      this.permissions.forEach((permission) => {
        data[permission.toLowerCase()] = 1;
      });

      try {
        await createMemberRole(this.groupId, data);
        this.$emit('success');
      } catch (error) {
        this.alert = createAlert({
          message: error?.response?.data?.message || s__('MemberRole|Failed to create role.'),
        });
      }
    },
  },
  BASE_ROLES,
};
</script>

<template>
  <gl-form @submit.prevent="createMemberRole">
    <h4 class="gl-mt-0">{{ s__('MemberRole|Create new role') }}</h4>
    <div class="row">
      <gl-form-group
        class="col-md-4"
        :label="s__('MemberRole|Base role to use as template')"
        :description="s__('MemberRole|Select a standard role to add permissions.')"
        :invalid-feedback="__('This field is required.')"
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
        :label="s__('MemberRole|Role name')"
        :description="s__('MemberRole|Enter a short name.')"
        :invalid-feedback="__('This field is required.')"
        label-for="role-name"
      >
        <gl-form-input
          id="role-name"
          v-model.trim="name"
          :placeholder="s__('MemberRole|Incident manager')"
          :state="nameValid"
        />
      </gl-form-group>

      <gl-form-group class="col-lg-8" :label="s__('MemberRole|Description')">
        <gl-form-textarea v-model="description" />
      </gl-form-group>
    </div>

    <gl-form-group :label="s__('MemberRole|Permissions')">
      <gl-form-checkbox-group v-model="permissions" :state="permissionsValid ? null : false">
        <gl-form-checkbox
          v-for="permission in selectablePermissions"
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
        data-testid="submit-button"
        variant="confirm"
        class="js-no-auto-disable"
      >
        {{ s__('MemberRole|Create new role') }}
      </gl-button>
      <gl-button type="reset" data-testid="cancel-button" @click="cancel">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </gl-form>
</template>

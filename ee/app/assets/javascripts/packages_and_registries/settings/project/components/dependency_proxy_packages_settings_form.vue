<script>
import { GlFormGroup, GlFormInput, GlSkeletonLoader, GlToggle } from '@gitlab/ui';

export default {
  name: 'DependencyProxyPackagesSettingsForm',
  components: {
    GlFormGroup,
    GlFormInput,
    GlSkeletonLoader,
    GlToggle,
  },
  props: {
    value: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      mavenExternalRegistryPassword: '',
    };
  },
  computed: {
    prefilledForm() {
      return {
        ...this.value,
      };
    },
  },
};
</script>

<template>
  <gl-skeleton-loader v-if="isLoading" />
  <form v-else>
    <gl-toggle
      v-model="prefilledForm.enabled"
      :label="s__('DependencyProxy|Enable Dependency Proxy')"
    />
    <h5 class="gl-mt-6">{{ s__('PackageRegistry|Maven') }}</h5>
    <gl-form-group
      :label="__('URL')"
      :description="s__('DependencyProxy|Base URL of the external registry.')"
    >
      <gl-form-input v-model="prefilledForm.mavenExternalRegistryUrl" width="xl" />
    </gl-form-group>
    <gl-form-group
      :label="__('Username')"
      :description="s__('DependencyProxy|Username of the external registry.')"
    >
      <gl-form-input v-model="prefilledForm.mavenExternalRegistryUsername" width="xl" />
    </gl-form-group>
    <gl-form-group
      :label="__('Password')"
      :description="s__('DependencyProxy|Password for your external registry.')"
    >
      <gl-form-input v-model="mavenExternalRegistryPassword" width="xl" type="password" />
    </gl-form-group>
  </form>
</template>

<script>
import { GlAlert, GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';
import Tracking from '~/tracking';
import { __ } from '~/locale';
import updateDependencyProxyMavenPackagesSettings from 'ee_component/packages_and_registries/settings/project/graphql/mutations/update_dependency_proxy_maven_packages_settings.mutation.graphql';
import { cacheUpdateDependencyProxyPackagesSettings } from 'ee_component/packages_and_registries/settings/project/graphql/utils/cache_update';

export default {
  name: 'MavenForm',
  components: {
    GlAlert,
    GlButton,
    GlFormGroup,
    GlFormInput,
  },
  mixins: [Tracking.mixin()],
  inject: ['projectPath'],
  props: {
    data: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      tracking: {
        label: 'dependendency_proxy_packages_settings',
      },
      mavenExternalRegistryPassword: '',
      alertMessage: '',
      updateInProgress: false,
    };
  },
  computed: {
    prefilledForm() {
      return {
        ...this.data,
      };
    },
    showAlert() {
      return this.alertMessage;
    },
  },
  methods: {
    mutationVariables(payload) {
      return {
        input: {
          projectPath: this.projectPath,
          mavenExternalRegistryPassword: this.mavenExternalRegistryPassword,
          ...payload,
        },
      };
    },
    async submit() {
      this.track('submit_dependency_proxy_maven_packages_settings');
      this.updateInProgress = true;
      this.alertMessage = '';
      await this.$apollo
        .mutate({
          mutation: updateDependencyProxyMavenPackagesSettings,
          variables: this.mutationVariables({ ...this.prefilledForm }),
          update: cacheUpdateDependencyProxyPackagesSettings(this.projectPath),
        })
        .then(({ data }) => {
          const [errorMessage] = data?.updateDependencyProxyPackagesSettings?.errors ?? [];
          if (errorMessage) {
            throw errorMessage;
          }
          this.mavenExternalRegistryPassword = '';
          this.$toast.show(__('Settings saved successfully.'));
        })
        .catch((errorMessage) => {
          this.alertMessage = errorMessage;
        })
        .finally(() => {
          this.updateInProgress = false;
        });
    },
  },
};
</script>

<template>
  <div>
    <h5 class="gl-mt-6">{{ s__('PackageRegistry|Maven') }}</h5>
    <gl-alert
      v-if="showAlert"
      variant="danger"
      class="gl-my-4"
      dismissible
      @dismiss="alertMessage = ''"
    >
      {{ alertMessage }}
    </gl-alert>
    <form @submit.prevent="submit">
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

      <div class="gl-mt-6 gl-display-flex gl-align-items-center">
        <gl-button
          type="submit"
          :disabled="updateInProgress"
          :loading="updateInProgress"
          category="primary"
          variant="confirm"
          class="js-no-auto-disable gl-mr-4"
        >
          {{ __('Save changes') }}
        </gl-button>
      </div>
    </form>
  </div>
</template>

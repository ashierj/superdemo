<script>
import { GlFormGroup, GlFormInput, GlSkeletonLoader, GlToggle } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import updateDependencyProxyPackagesSettings from 'ee_component/packages_and_registries/settings/project/graphql/mutations/update_dependency_proxy_packages_settings.mutation.graphql';
import { updateDependencyProxyPackagesToggleSettings } from 'ee_component/packages_and_registries/settings/project/graphql/utils/cache_update';

export default {
  name: 'DependencyProxyPackagesSettingsForm',
  components: {
    GlFormGroup,
    GlFormInput,
    GlSkeletonLoader,
    GlToggle,
  },
  mixins: [Tracking.mixin()],
  inject: ['projectPath'],
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
      tracking: {
        label: 'dependendency_proxy_packages_settings',
      },
      mavenExternalRegistryPassword: '',
    };
  },
  computed: {
    prefilledForm() {
      return {
        ...this.value,
      };
    },
    enabled: {
      get() {
        return this.value.enabled;
      },
      set(enabled) {
        this.updateSettings({ enabled });
      },
    },
  },
  methods: {
    mutationVariables(payload) {
      return {
        input: {
          projectPath: this.projectPath,
          ...payload,
        },
      };
    },
    optimisticResponse({ enabled }) {
      return {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        __typename: 'Mutation',
        updateDependencyProxyPackagesSettings: {
          __typename: 'UpdateDependencyProxyPackagesSettingsPayload',
          errors: [],
          dependencyProxyPackagesSetting: {
            ...this.value,
            enabled,
          },
        },
      };
    },
    async updateSettings({ enabled }) {
      this.track('toggle_dependency_proxy_packages_settings');
      await this.$apollo
        .mutate({
          mutation: updateDependencyProxyPackagesSettings,
          variables: this.mutationVariables({ enabled }),
          update: updateDependencyProxyPackagesToggleSettings(this.projectPath),
          optimisticResponse: this.optimisticResponse({ enabled }),
        })
        .then(({ data }) => {
          const [errorMessage] = data?.updateDependencyProxyPackagesSettings?.errors ?? [];
          if (errorMessage) {
            throw errorMessage;
          } else {
            this.$toast.show(__('Settings saved successfully.'));
          }
        })
        .catch(() => {
          this.$toast.show(__('An error occurred while saving the settings.'));
        });
    },
  },
};
</script>

<template>
  <gl-skeleton-loader v-if="isLoading" />
  <div v-else>
    <gl-toggle v-model="enabled" :label="s__('DependencyProxy|Enable Dependency Proxy')" />
    <form>
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
  </div>
</template>

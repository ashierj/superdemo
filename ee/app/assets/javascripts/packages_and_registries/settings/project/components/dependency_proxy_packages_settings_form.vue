<script>
import { GlSkeletonLoader, GlToggle } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import MavenForm from 'ee_component/packages_and_registries/settings/project/components/maven_form.vue';
import updateDependencyProxyPackagesSettings from 'ee_component/packages_and_registries/settings/project/graphql/mutations/update_dependency_proxy_packages_settings.mutation.graphql';
import { cacheUpdateDependencyProxyPackagesSettings } from 'ee_component/packages_and_registries/settings/project/graphql/utils/cache_update';

export default {
  name: 'DependencyProxyPackagesSettingsForm',
  components: {
    GlSkeletonLoader,
    GlToggle,
    MavenForm,
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
    };
  },
  computed: {
    mavenFormData() {
      const { mavenExternalRegistryUrl, mavenExternalRegistryUsername } = this.value;
      return {
        mavenExternalRegistryUrl,
        mavenExternalRegistryUsername,
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
          update: cacheUpdateDependencyProxyPackagesSettings(this.projectPath),
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
    <maven-form :data="mavenFormData" />
  </div>
</template>

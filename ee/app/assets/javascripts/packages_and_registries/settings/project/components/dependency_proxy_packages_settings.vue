<script>
import { GlAlert } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import SettingsBlock from '~/packages_and_registries/shared/components/settings_block.vue';
import getDependencyProxyPackagesSettings from 'ee_component/packages_and_registries/settings/project/graphql/queries/get_dependency_proxy_packages_settings.query.graphql';
import DependencyProxyPackagesSettingsForm from 'ee_component/packages_and_registries/settings/project/components/dependency_proxy_packages_settings_form.vue';

export default {
  name: 'DependencyProxyPackagesSettings',
  components: {
    DependencyProxyPackagesSettingsForm,
    GlAlert,
    SettingsBlock,
  },
  inject: {
    projectPath: {
      default: '',
    },
  },
  apollo: {
    dependencyProxyPackagesSettings: {
      query: getDependencyProxyPackagesSettings,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update: (data) => data.project?.dependencyProxyPackagesSetting || {},
      error(e) {
        this.fetchSettingsError = e;
        Sentry.captureException(e);
      },
    },
  },
  data() {
    return {
      dependencyProxyPackagesSettings: {},
      fetchSettingsError: false,
    };
  },
};
</script>

<template>
  <settings-block>
    <template #title>
      <span data-testid="title">{{ s__('DependencyProxy|Dependency Proxy') }}</span></template
    >
    <template #description>
      <span data-testid="description">
        {{
          s__(
            'DependencyProxy|Enable the Dependency Proxy for packages, and configure connection settings for external registries.',
          )
        }}
      </span>
    </template>
    <template #default>
      <gl-alert v-if="fetchSettingsError" variant="warning" :dismissible="false">
        {{
          s__('DependencyProxy|Something went wrong while fetching the dependency proxy settings.')
        }}
      </gl-alert>
      <dependency-proxy-packages-settings-form
        v-else
        v-model="dependencyProxyPackagesSettings"
        :is-loading="$apollo.queries.dependencyProxyPackagesSettings.loading"
      />
    </template>
  </settings-block>
</template>

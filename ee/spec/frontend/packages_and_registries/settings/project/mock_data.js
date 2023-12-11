export const dependencyProxyPackagesSettingsData = {
  __typename: 'DependencyProxyPackagesSetting',
  enabled: true,
  mavenExternalRegistryUrl: 'https://test.dev',
  mavenExternalRegistryUsername: 'user1',
};

export const dependencyProxyPackagesSettingsPayload = (override) => ({
  data: {
    project: {
      id: '1',
      dependencyProxyPackagesSetting: {
        ...dependencyProxyPackagesSettingsData,
        ...override,
      },
    },
  },
});

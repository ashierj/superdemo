import { produce } from 'immer';
import getDependencyProxyPackagesSettingsQuery from 'ee_component/packages_and_registries/settings/project/graphql/queries/get_dependency_proxy_packages_settings.query.graphql';

export const updateDependencyProxyPackagesToggleSettings = (projectPath) => (
  client,
  { data: updatedData },
) => {
  const queryAndParams = {
    query: getDependencyProxyPackagesSettingsQuery,
    variables: { projectPath },
  };

  const sourceData = client.readQuery(queryAndParams);

  const data = produce(sourceData, (draftState) => {
    if (draftState.project && updatedData.updateDependencyProxyPackagesSettings) {
      draftState.project.dependencyProxyPackagesSetting = {
        ...draftState.project.dependencyProxyPackagesSetting,
        ...updatedData.updateDependencyProxyPackagesSettings.dependencyProxyPackagesSetting,
      };
    }
  });

  client.writeQuery({
    ...queryAndParams,
    data,
  });
};

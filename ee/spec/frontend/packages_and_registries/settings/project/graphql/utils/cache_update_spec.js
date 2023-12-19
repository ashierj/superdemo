import { updateDependencyProxyPackagesToggleSettings } from 'ee_component/packages_and_registries/settings/project/graphql/utils/cache_update';
import dependencyProxyPackagesSettingsQuery from 'ee_component/packages_and_registries/settings/project/graphql/queries/get_dependency_proxy_packages_settings.query.graphql';

describe('Package and Registries settings project cache updates', () => {
  let client;

  const updateDependencyProxyPackagesSettingsPayload = {
    dependencyProxyPackagesSetting: {
      enabled: false,
    },
  };

  const cacheMock = {
    project: {
      dependencyProxyPackagesSetting: {
        enabled: true,
      },
    },
  };

  const queryAndVariables = {
    query: dependencyProxyPackagesSettingsQuery,
    variables: { projectPath: 'path' },
  };

  beforeEach(() => {
    client = {
      readQuery: jest.fn().mockReturnValue(cacheMock),
      writeQuery: jest.fn(),
    };
  });

  describe.each([updateDependencyProxyPackagesSettingsPayload, undefined])(
    'updateDependencyProxyPackagesSettings',
    (updateDependencyProxyPackagesSettings) => {
      const payload = {
        data: {
          updateDependencyProxyPackagesSettings,
        },
      };
      it('calls readQuery', () => {
        updateDependencyProxyPackagesToggleSettings('path')(client, payload);
        expect(client.readQuery).toHaveBeenCalledWith(queryAndVariables);
      });

      it('writes the correct result in the cache', () => {
        updateDependencyProxyPackagesToggleSettings('path')(client, payload);
        expect(client.writeQuery).toHaveBeenCalledWith({
          ...queryAndVariables,
          data: {
            project: {
              ...cacheMock.project,
              ...payload.data.updateDependencyProxyPackagesSettings,
            },
          },
        });
      });
    },
  );
});

import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlSkeletonLoader, GlToggle } from '@gitlab/ui';
import Tracking from '~/tracking';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DependencyProxyPackagesSettingsForm from 'ee_component/packages_and_registries/settings/project/components/dependency_proxy_packages_settings_form.vue';
import updateDependencyProxyPackagesSettings from 'ee_component/packages_and_registries/settings/project/graphql/mutations/update_dependency_proxy_packages_settings.mutation.graphql';
import dependencyProxyPackagesSettingsQuery from 'ee_component/packages_and_registries/settings/project/graphql/queries/get_dependency_proxy_packages_settings.query.graphql';
import MavenForm from 'ee_component/packages_and_registries/settings/project/components/maven_form.vue';
import {
  dependencyProxyPackagesSettingsData,
  dependencyProxyPackagesSettingsPayload,
  dependencyProxyPackagesToggleSettingMutationMock,
  mutationErrorMock,
} from '../mock_data';

Vue.use(VueApollo);

describe('Dependency proxy packages settings form', () => {
  let wrapper;
  let apolloProvider;
  let updateToggleSettingsMutationResolver;
  let show;

  const {
    data: {
      project: { dependencyProxyPackagesSetting },
    },
  } = dependencyProxyPackagesSettingsPayload();

  const defaultProps = {
    value: { ...dependencyProxyPackagesSetting },
  };

  const defaultProvidedValues = {
    projectPath: 'path',
  };

  const trackingPayload = {
    label: 'dependendency_proxy_packages_settings',
  };

  const findEnableProxyToggle = () => wrapper.findComponent(GlToggle);
  const findLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findMavenForm = () => wrapper.findComponent(MavenForm);

  const mountComponent = ({ props = defaultProps } = {}) => {
    wrapper = shallowMountExtended(DependencyProxyPackagesSettingsForm, {
      provide: defaultProvidedValues,
      propsData: { ...props },
      apolloProvider,
      mocks: {
        $toast: {
          show,
        },
      },
    });
  };

  const mountComponentWithApollo = ({ props = defaultProps } = {}) => {
    const requestHandlers = [
      [updateDependencyProxyPackagesSettings, updateToggleSettingsMutationResolver],
    ];

    apolloProvider = createMockApollo(requestHandlers);
    mountComponent({
      propsData: {
        ...props,
      },
    });
  };

  describe('fields', () => {
    it('are hidden when isLoading is set to true', () => {
      mountComponent({
        props: {
          ...defaultProps,
          isLoading: true,
        },
      });

      expect(findEnableProxyToggle().exists()).toBe(false);
      expect(findMavenForm().exists()).toBe(false);
      expect(findLoader().exists()).toBe(true);
    });

    it('are visible when isLoading is set to false', () => {
      const {
        enabled,
        mavenExternalRegistryUrl,
        mavenExternalRegistryUsername,
      } = dependencyProxyPackagesSetting;

      mountComponent();

      expect(findLoader().exists()).toBe(false);
      expect(findEnableProxyToggle().props('value')).toBe(enabled);
      expect(findMavenForm().props('data')).toStrictEqual({
        mavenExternalRegistryUrl,
        mavenExternalRegistryUsername,
      });
    });
  });

  describe('enable proxy toggle', () => {
    it('when enabled', () => {
      mountComponent();

      expect(findEnableProxyToggle().props()).toMatchObject({
        label: 'Enable Dependency Proxy',
        value: true,
      });
    });

    it('when disabled', () => {
      mountComponent({
        props: {
          value: {
            ...defaultProps.value,
            enabled: false,
          },
        },
      });

      expect(findEnableProxyToggle().props('value')).toBe(false);
    });

    describe('mutation', () => {
      beforeEach(() => {
        show = jest.fn();
        jest.spyOn(Tracking, 'event');
      });

      const fillApolloCache = () => {
        apolloProvider.defaultClient.cache.writeQuery({
          query: dependencyProxyPackagesSettingsQuery,
          variables: {
            projectPath: defaultProvidedValues.projectPath,
          },
          ...dependencyProxyPackagesSettingsPayload(),
        });
      };

      describe('success state', () => {
        beforeEach(() => {
          updateToggleSettingsMutationResolver = jest
            .fn()
            .mockResolvedValue(dependencyProxyPackagesToggleSettingMutationMock());
        });

        it('shows a toast with success message', async () => {
          mountComponentWithApollo();

          fillApolloCache();
          findEnableProxyToggle().vm.$emit('change', false);

          await waitForPromises();

          expect(show).toHaveBeenCalledWith('Settings saved successfully.');
        });

        it('has an optimistic response', () => {
          mountComponentWithApollo();

          fillApolloCache();

          apolloProvider.defaultClient.mutate = jest
            .fn()
            .mockResolvedValue(dependencyProxyPackagesToggleSettingMutationMock());

          expect(findEnableProxyToggle().props('value')).toBe(true);

          findEnableProxyToggle().vm.$emit('change', false);

          expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith(
            expect.objectContaining({
              optimisticResponse: {
                __typename: 'Mutation',
                updateDependencyProxyPackagesSettings: {
                  __typename: 'UpdateDependencyProxyPackagesSettingsPayload',
                  errors: [],
                  dependencyProxyPackagesSetting: {
                    ...dependencyProxyPackagesSettingsData,
                    enabled: false,
                  },
                },
              },
            }),
          );
        });

        it('tracks the toggle event', () => {
          mountComponentWithApollo();

          fillApolloCache();
          findEnableProxyToggle().vm.$emit('change', false);

          expect(Tracking.event).toHaveBeenCalledWith(
            undefined,
            'toggle_dependency_proxy_packages_settings',
            trackingPayload,
          );
        });
      });

      describe('errors', () => {
        it('mutation payload with root level errors', async () => {
          updateToggleSettingsMutationResolver = jest.fn().mockResolvedValue(mutationErrorMock);

          mountComponentWithApollo();

          fillApolloCache();

          findEnableProxyToggle().vm.$emit('change', false);

          await waitForPromises();

          expect(show).toHaveBeenCalledWith('An error occurred while saving the settings.');
        });

        it.each`
          type         | mutationResolverMock
          ${'local'}   | ${jest.fn().mockResolvedValue(dependencyProxyPackagesToggleSettingMutationMock({ errors: ['foo'] }))}
          ${'network'} | ${jest.fn().mockRejectedValue()}
        `('mutation payload with $type error', async ({ mutationResolverMock }) => {
          updateToggleSettingsMutationResolver = mutationResolverMock;
          mountComponentWithApollo();

          fillApolloCache();
          findEnableProxyToggle().vm.$emit('change', false);

          await waitForPromises();

          expect(show).toHaveBeenCalledWith('An error occurred while saving the settings.');
        });
      });
    });
  });
});

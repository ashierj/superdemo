import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlFormGroup, GlFormInput, GlSkeletonLoader, GlToggle } from '@gitlab/ui';
import Tracking from '~/tracking';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DependencyProxyPackagesSettingsForm from 'ee_component/packages_and_registries/settings/project/components/dependency_proxy_packages_settings_form.vue';
import updateDependencyProxyPackagesSettings from 'ee_component/packages_and_registries/settings/project/graphql/mutations/update_dependency_proxy_packages_settings.mutation.graphql';
import dependencyProxyPackagesSettingsQuery from 'ee_component/packages_and_registries/settings/project/graphql/queries/get_dependency_proxy_packages_settings.query.graphql';
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

  const findForm = () => wrapper.find('form');
  const findEnableProxyToggle = () => wrapper.findComponent(GlToggle);
  const findLoader = () => wrapper.findComponent(GlSkeletonLoader);

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

  describe('form', () => {
    it('is hidden when isLoading is set to true', () => {
      mountComponent({
        props: {
          ...defaultProps,
          isLoading: true,
        },
      });

      expect(findForm().exists()).toBe(false);
      expect(findLoader().exists()).toBe(true);
    });

    it('is visible when isLoading is set to false', () => {
      mountComponent();

      expect(findForm().exists()).toBe(true);
      expect(findLoader().exists()).toBe(false);
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

        it('emits a success event', async () => {
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

  describe('maven registry', () => {
    it('renders header', () => {
      mountComponent();

      expect(wrapper.find('h5').text()).toBe('Maven');
    });

    it.each`
      index | field         | description                               | value
      ${0}  | ${'URL'}      | ${'Base URL of the external registry.'}   | ${defaultProps.value.mavenExternalRegistryUrl}
      ${1}  | ${'Username'} | ${'Username of the external registry.'}   | ${defaultProps.value.mavenExternalRegistryUsername}
      ${2}  | ${'Password'} | ${'Password for your external registry.'} | ${''}
    `('renders $field', ({ index, field, description, value }) => {
      mountComponent();

      const formGroup = wrapper.findAllComponents(GlFormGroup).at(index);
      const formInput = formGroup.findComponent(GlFormInput);

      expect(formGroup.attributes()).toMatchObject({
        label: field,
        description,
      });

      expect(formInput.attributes('value')).toBe(value);
    });
  });
});

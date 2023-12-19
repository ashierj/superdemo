import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';
import Tracking from '~/tracking';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import updateDependencyProxyMavenPackagesSettings from 'ee_component/packages_and_registries/settings/project/graphql/mutations/update_dependency_proxy_maven_packages_settings.mutation.graphql';
import dependencyProxyPackagesSettingsQuery from 'ee_component/packages_and_registries/settings/project/graphql/queries/get_dependency_proxy_packages_settings.query.graphql';
import MavenForm from 'ee_component/packages_and_registries/settings/project/components/maven_form.vue';
import {
  dependencyProxyPackagesSettingsPayload,
  dependencyProxyMavenPackagesSettingMutationMock,
  mutationErrorMock,
} from '../mock_data';

Vue.use(VueApollo);

describe('maven form', () => {
  let wrapper;
  let apolloProvider;
  let updateMavenSettingsMutationResolver;
  let show;

  const {
    data: {
      project: { dependencyProxyPackagesSetting },
    },
  } = dependencyProxyPackagesSettingsPayload();

  const {
    mavenExternalRegistryUrl,
    mavenExternalRegistryUsername,
  } = dependencyProxyPackagesSetting;

  const defaultProps = {
    data: { mavenExternalRegistryUrl, mavenExternalRegistryUsername },
  };

  const defaultProvidedValues = {
    projectPath: 'path',
  };

  const trackingPayload = {
    label: 'dependendency_proxy_packages_settings',
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findForm = () => wrapper.find('form');
  const findSubmitButton = () => wrapper.findComponent(GlButton);

  const mountComponent = ({ props = defaultProps } = {}) => {
    wrapper = shallowMountExtended(MavenForm, {
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
      [updateDependencyProxyMavenPackagesSettings, updateMavenSettingsMutationResolver],
    ];

    apolloProvider = createMockApollo(requestHandlers);
    mountComponent({
      propsData: {
        ...props,
      },
    });
  };

  it('renders header', () => {
    mountComponent();

    expect(wrapper.findByRole('heading', { level: 5, name: 'Maven' }).exists()).toBe(true);
  });

  it.each`
    index | field         | description                               | value
    ${0}  | ${'URL'}      | ${'Base URL of the external registry.'}   | ${mavenExternalRegistryUrl}
    ${1}  | ${'Username'} | ${'Username of the external registry.'}   | ${mavenExternalRegistryUsername}
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

  it('renders submit button', () => {
    mountComponent();

    expect(findSubmitButton().text()).toBe('Save changes');
    expect(findSubmitButton().attributes('disabled')).toBeUndefined();
    expect(findSubmitButton().props('loading')).toBe(false);
  });

  it('alert is hidden', () => {
    mountComponent();

    expect(findAlert().exists()).toBe(false);
  });

  describe('mutation', () => {
    beforeEach(() => {
      updateMavenSettingsMutationResolver = jest
        .fn()
        .mockResolvedValue(dependencyProxyMavenPackagesSettingMutationMock());
      show = jest.fn();
      jest.spyOn(Tracking, 'event');
    });

    const findPasswordInput = () =>
      wrapper.findAllComponents(GlFormGroup).at(2).findComponent(GlFormInput);

    it('tracks the submit event', () => {
      mountComponentWithApollo();

      findForm().trigger('submit');

      expect(Tracking.event).toHaveBeenCalledWith(
        undefined,
        'submit_dependency_proxy_maven_packages_settings',
        trackingPayload,
      );
    });

    it('sets submit button loading & disabled prop', async () => {
      mountComponentWithApollo();

      findForm().trigger('submit');

      await nextTick();

      expect(findSubmitButton().props()).toMatchObject({
        loading: true,
        disabled: true,
      });
    });

    it('is called with the right arguments', async () => {
      mountComponentWithApollo();

      apolloProvider.defaultClient.mutate = jest
        .fn()
        .mockResolvedValue(dependencyProxyMavenPackagesSettingMutationMock());

      findPasswordInput().vm.$emit('input', 'password');

      await nextTick();

      findForm().trigger('submit');

      await nextTick();

      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith(
        expect.objectContaining({
          mutation: updateDependencyProxyMavenPackagesSettings,
          variables: {
            input: {
              projectPath: defaultProvidedValues.projectPath,
              mavenExternalRegistryUrl,
              mavenExternalRegistryUsername,
              mavenExternalRegistryPassword: 'password',
            },
          },
        }),
      );
    });

    describe('success state', () => {
      const fillApolloCache = () => {
        apolloProvider.defaultClient.cache.writeQuery({
          query: dependencyProxyPackagesSettingsQuery,
          variables: {
            projectPath: defaultProvidedValues.projectPath,
          },
          ...dependencyProxyPackagesSettingsPayload(),
        });
      };

      it('shows a toast with success message', async () => {
        mountComponentWithApollo();
        fillApolloCache();

        findForm().trigger('submit');

        await waitForPromises();

        expect(show).toHaveBeenCalledWith('Settings saved successfully.');
        expect(findSubmitButton().props()).toMatchObject({
          loading: false,
          disabled: false,
        });
      });

      it('password field is reset', async () => {
        mountComponentWithApollo();
        fillApolloCache();

        findPasswordInput().vm.$emit('input', 'password');

        await nextTick();

        expect(findPasswordInput().attributes('value')).toBe('password');

        findForm().trigger('submit');

        await waitForPromises();

        expect(findPasswordInput().attributes('value')).toBe('');
      });
    });

    describe('errors', () => {
      it('shows alert with message', async () => {
        updateMavenSettingsMutationResolver = jest.fn().mockResolvedValue(mutationErrorMock);

        mountComponentWithApollo();

        findForm().trigger('submit');

        await waitForPromises();

        expect(findAlert().text()).toBe('Error: Some error');
        expect(findAlert().props('variant')).toBe('danger');
        expect(findAlert().props('dismissible')).toBe(true);
        expect(show).not.toHaveBeenCalled();

        expect(findSubmitButton().props()).toMatchObject({
          loading: false,
          disabled: false,
        });
      });

      it('password field is not reset', async () => {
        updateMavenSettingsMutationResolver = jest.fn().mockResolvedValue(mutationErrorMock);
        mountComponentWithApollo();

        findPasswordInput().vm.$emit('input', 'password');
        findForm().trigger('submit');

        await waitForPromises();

        expect(findPasswordInput().attributes('value')).toBe('password');
      });

      it('mutation payload with network error', async () => {
        updateMavenSettingsMutationResolver = jest.fn().mockRejectedValue();
        mountComponentWithApollo();

        findForm().trigger('submit');

        await waitForPromises();

        expect(findAlert().text()).toBe('Error');
        expect(findAlert().props('variant')).toBe('danger');
        expect(show).not.toHaveBeenCalled();
      });
    });
  });
});

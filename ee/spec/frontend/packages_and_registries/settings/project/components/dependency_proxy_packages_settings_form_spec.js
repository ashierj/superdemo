import { GlFormGroup, GlFormInput, GlSkeletonLoader, GlToggle } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DependencyProxyPackagesSettingsForm from 'ee_component/packages_and_registries/settings/project/components/dependency_proxy_packages_settings_form.vue';
import { dependencyProxyPackagesSettingsPayload } from '../mock_data';

describe('Dependency proxy packages settings form', () => {
  let wrapper;

  const {
    data: {
      project: { dependencyProxyPackagesSetting },
    },
  } = dependencyProxyPackagesSettingsPayload();

  const defaultProps = {
    value: { ...dependencyProxyPackagesSetting },
  };

  const findForm = () => wrapper.find('form');
  const findEnableProxyToggle = () => wrapper.findComponent(GlToggle);
  const findLoader = () => wrapper.findComponent(GlSkeletonLoader);

  const mountComponent = ({ props = defaultProps } = {}) => {
    wrapper = shallowMountExtended(DependencyProxyPackagesSettingsForm, {
      propsData: { ...props },
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

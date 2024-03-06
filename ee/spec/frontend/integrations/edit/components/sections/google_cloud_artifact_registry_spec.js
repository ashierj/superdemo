import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import IntegrationSectionGoogleCloudArtifactRegistry from 'ee_component/integrations/edit/components/sections/google_cloud_artifact_registry.vue';
import Configuration from '~/integrations/edit/components/sections/configuration.vue';
import Connection from '~/integrations/edit/components/sections/connection.vue';
import ConfigurationInstructions from 'ee/integrations/edit/components/google_cloud_artifact_registry/configuration_instructions.vue';
import { createStore } from '~/integrations/edit/store';
import { mockIntegrationProps } from '../../mock_data';

describe('IntegrationSectionGoogleCloudArtifactRegistry', () => {
  let wrapper;

  const findViewArtifactsButton = () => wrapper.findComponent(GlButton);
  const findConfigurationInstructions = () => wrapper.findComponent(ConfigurationInstructions);
  const findConfiguration = () => wrapper.findComponent(Configuration);
  const findConnection = () => wrapper.findComponent(Connection);
  const findTitle = () => wrapper.find('h3');

  const createComponent = ({ operating = true } = {}) => {
    const store = createStore({
      customState: { ...mockIntegrationProps, operating },
    });

    wrapper = shallowMount(IntegrationSectionGoogleCloudArtifactRegistry, {
      store,
    });
  };

  it('renders a button to view artifacts', () => {
    createComponent();

    expect(findViewArtifactsButton().text()).toBe('View artifacts');
    expect(findViewArtifactsButton().props('icon')).toBe('deployments');
    expect(findViewArtifactsButton().attributes('href')).toBe('/path/to/artifact/registry');
  });

  it('hides button to view artifacts when `operating=false`', () => {
    createComponent({ operating: false });

    expect(findViewArtifactsButton().exists()).toBe(false);
  });

  it('renders connection component', () => {
    createComponent();

    expect(findConnection().exists()).toBe(true);
  });

  it('renders form title', () => {
    createComponent();

    expect(findTitle().text()).toBe('Repository');
  });

  it('renders configuration component', () => {
    createComponent();

    expect(findConfiguration().props('fields')).toBe(mockIntegrationProps.fields);
  });

  it('renders configuration instructions', () => {
    createComponent();

    expect(findConfigurationInstructions().exists()).toBe(true);
  });
});

import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import IntegrationSectionGoogleCloudArtifactRegistry from 'ee_component/integrations/edit/components/sections/google_cloud_artifact_registry.vue';
import { createStore } from '~/integrations/edit/store';

import { mockIntegrationProps } from '../../mock_data';

describe('IntegrationSectionGoogleCloudArtifactRegistry', () => {
  let wrapper;

  const findViewArtifactsButton = () => wrapper.findComponent(GlButton);

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
});

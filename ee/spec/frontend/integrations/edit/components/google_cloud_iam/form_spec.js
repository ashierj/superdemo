import { shallowMount } from '@vue/test-utils';
import GcIamForm from 'ee/integrations/edit/components/google_cloud_iam/form.vue';
import Configuration from '~/integrations/edit/components/sections/configuration.vue';
import Connection from '~/integrations/edit/components/sections/connection.vue';
import { createStore } from '~/integrations/edit/store';

describe('IntegrationSectionGoogleCloudIAM', () => {
  let wrapper;

  const createComponent = ({ fields = [], showActive = true } = {}) => {
    const store = createStore({
      defaultState: {
        showActive,
      },
    });

    wrapper = shallowMount(GcIamForm, {
      store,
      propsData: { fields },
    });
  };

  const findConfigurations = () => wrapper.findAllComponents(Configuration);
  const findConnection = () => wrapper.findComponent(Connection);
  const findHeaders = () => wrapper.findAll('h4');

  it('renders Connection component', () => {
    createComponent();

    expect(findConnection().exists()).toBe(true);
  });

  it('shows two headers', () => {
    createComponent();
    const headers = findHeaders();

    expect(headers.at(0).text()).toBe('Google Cloud project');
    expect(headers.at(1).text()).toBe('Workload identity federation');
  });

  describe('Configuration components', () => {
    it('renders Google Cloud project fields', () => {
      createComponent({
        fields: [
          { name: 'workload_identity_federation_project_id', type: 'input' },
          { name: 'dummy', type: 'input' }, // Ignored,
        ],
      });

      const configurations = findConfigurations();
      expect(configurations.at(0).props('fields')).toHaveLength(1);
      expect(configurations.at(1).props('fields')).toHaveLength(0);
    });

    it('renders Workload identity federation fields', () => {
      createComponent({
        fields: [
          { name: 'workload_identity_pool_id', type: 'input' },
          { name: 'dummy', type: 'input' }, // Ignored,
        ],
      });

      const configurations = findConfigurations();
      expect(configurations.at(0).props('fields')).toHaveLength(0);
      expect(configurations.at(1).props('fields')).toHaveLength(1);
    });
  });
});

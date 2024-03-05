import { shallowMount } from '@vue/test-utils';
import IntegrationSectionGoogleCloudIAM from 'ee_component/integrations/edit/components/sections/google_cloud_iam.vue';
import GcIamForm from 'ee_component/integrations/edit/components/google_cloud_iam/form.vue';
import { createStore } from '~/integrations/edit/store';

describe('IntegrationSectionGoogleCloudIAM', () => {
  let wrapper;

  const createComponent = () => {
    const store = createStore({
      customState: {
        fields: [],
      },
    });

    wrapper = shallowMount(IntegrationSectionGoogleCloudIAM, {
      store,
    });
  };

  const findGcIamForm = () => wrapper.findComponent(GcIamForm);

  it('renders Google Cloud IAM form', () => {
    createComponent();

    expect(findGcIamForm().exists()).toBe(true);
  });
});

import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import IntegrationSectionGoogleCloudIAM from 'ee_component/integrations/edit/components/sections/google_cloud_iam.vue';
import {
  STATE_EMPTY,
  STATE_GUIDED,
  STATE_MANUAL,
} from 'ee/integrations/edit/components/google_cloud_iam/constants';
import EmptyState from 'ee/integrations/edit/components/google_cloud_iam/empty_state.vue';
import GcIamForm from 'ee/integrations/edit/components/google_cloud_iam/form.vue';
import GuidedSetup from 'ee/integrations/edit/components/google_cloud_iam/guided_setup.vue';
import ManualSetup from 'ee/integrations/edit/components/google_cloud_iam/manual_setup.vue';
import { createStore } from '~/integrations/edit/store';

describe('IntegrationSectionGoogleCloudIAM', () => {
  let wrapper;

  const createComponent = ({ fields = [] } = {}) => {
    const store = createStore({
      customState: {
        fields,
      },
    });

    wrapper = shallowMount(IntegrationSectionGoogleCloudIAM, {
      store,
    });
  };

  const findEmptyState = () => wrapper.findComponent(EmptyState);
  const findGcIamForm = () => wrapper.findComponent(GcIamForm);
  const findGuidedSetup = () => wrapper.findComponent(GuidedSetup);
  const findManualSetup = () => wrapper.findComponent(ManualSetup);

  describe('when Google Cloud IAM form is empty', () => {
    it('renders the empty state', () => {
      createComponent();

      expect(findEmptyState().exists()).toBe(true);
      expect(findGcIamForm().exists()).toBe(false);
    });
  });

  describe('when Google Cloud IAM form is not empty', () => {
    it('renders the Google Cloud IAM form', () => {
      createComponent({ fields: [{ value: '' }, { value: '1' }] });

      expect(findEmptyState().exists()).toBe(false);
      expect(findGcIamForm().exists()).toBe(true);
    });
  });

  describe('when `show` events are emitted', () => {
    it.each`
      initialState    | event           | componentEmitting  | hasEmptyState | hasGuidedSetup | hasManualSetup | hasGcIamForm
      ${STATE_EMPTY}  | ${STATE_GUIDED} | ${findEmptyState}  | ${false}      | ${true}        | ${false}       | ${false}
      ${STATE_EMPTY}  | ${STATE_MANUAL} | ${findEmptyState}  | ${false}      | ${false}       | ${true}        | ${true}
      ${STATE_GUIDED} | ${STATE_MANUAL} | ${findGuidedSetup} | ${false}      | ${false}       | ${true}        | ${true}
      ${STATE_MANUAL} | ${STATE_GUIDED} | ${findManualSetup} | ${false}      | ${true}        | ${false}       | ${false}
    `(
      "render correct components for the '$event' event",
      async ({
        initialState,
        event,
        componentEmitting,
        hasEmptyState,
        hasGuidedSetup,
        hasManualSetup,
        hasGcIamForm,
      }) => {
        createComponent();

        // Initial state
        findEmptyState().vm.$emit('show', initialState);
        await nextTick();

        componentEmitting().vm.$emit('show', event);
        await nextTick();

        expect(findEmptyState().exists()).toBe(hasEmptyState);
        expect(findGuidedSetup().exists()).toBe(hasGuidedSetup);
        expect(findManualSetup().exists()).toBe(hasManualSetup);
        expect(findGcIamForm().exists()).toBe(hasGcIamForm);
      },
    );
  });
});

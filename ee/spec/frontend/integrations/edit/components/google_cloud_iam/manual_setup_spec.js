import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { STATE_GUIDED } from 'ee/integrations/edit/components/google_cloud_iam/constants';
import ManualSetup from 'ee/integrations/edit/components/google_cloud_iam/manual_setup.vue';

describe('ManualSetup', () => {
  let wrapper;
  const createComponent = () => {
    wrapper = shallowMount(ManualSetup, { stubs: { GlSprintf } });
  };

  const findFirstLink = () => wrapper.findAllComponents(GlLink).at(0);

  beforeEach(() => {
    createComponent();
  });

  describe('Switch to guided setup link', () => {
    let switchLink;

    beforeEach(() => {
      switchLink = findFirstLink();
    });

    it('renders link', () => {
      expect(switchLink.text()).toBe('Switch to the guided setup');
    });

    it('emits `show` event', () => {
      expect(wrapper.emitted().show).toBeUndefined();

      switchLink.vm.$emit('click');

      expect(wrapper.emitted().show).toHaveLength(1);
      expect(wrapper.emitted().show[0]).toContain(STATE_GUIDED);
    });
  });
});

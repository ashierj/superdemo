import { GlButton, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { STATE_MANUAL } from 'ee/integrations/edit/components/google_cloud_iam/constants';
import GuidedSetup from 'ee/integrations/edit/components/google_cloud_iam/guided_setup.vue';
import { refreshCurrentPage } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  refreshCurrentPage: jest.fn(),
}));

describe('GuidedSetup', () => {
  let wrapper;
  const createComponent = () => {
    wrapper = shallowMount(GuidedSetup, { stubs: { GlSprintf } });
  };

  const findFirstLink = () => wrapper.findAllComponents(GlLink).at(0);
  const findButton = (variant) =>
    wrapper.findAllComponents(GlButton).filter((button) => button.props('variant') === variant);

  beforeEach(() => {
    createComponent();
  });

  describe('Switch to manual setup link', () => {
    let switchLink;

    beforeEach(() => {
      switchLink = findFirstLink();
    });

    it('renders link', () => {
      expect(switchLink.text()).toBe('Switch to the manual setup');
    });

    it('emits `show` event', () => {
      expect(wrapper.emitted().show).toBeUndefined();

      switchLink.vm.$emit('click');

      expect(wrapper.emitted().show).toHaveLength(1);
      expect(wrapper.emitted().show[0]).toContain(STATE_MANUAL);
    });
  });

  describe('Continue button', () => {
    let continueButton;

    beforeEach(() => {
      continueButton = findButton('confirm').at(0);
    });

    it('renders variant confirm button', () => {
      expect(continueButton.text()).toBe('Continue');
    });

    it('refreshes the page on the continue button', () => {
      expect(refreshCurrentPage).not.toHaveBeenCalled();

      continueButton.vm.$emit('click');

      expect(refreshCurrentPage).toHaveBeenCalled();
    });
  });

  describe('Cancel button', () => {
    let cancelButton;

    beforeEach(() => {
      cancelButton = findButton('default').at(0);
    });

    it('renders variant confirm button', () => {
      expect(cancelButton.text()).toBe('Cancel');
    });

    it('emits `show` event', () => {
      expect(wrapper.emitted().show).toBeUndefined();

      cancelButton.vm.$emit('click');

      expect(wrapper.emitted().show).toHaveLength(1);
      expect(wrapper.emitted().show[0]).toContain('empty');
    });
  });
});

import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import SamlReloadModal from 'ee/saml_sso/components/saml_reload_modal.vue';
import { getExpiringSamlSession } from 'ee/saml_sso/saml_sessions';
import waitForPromises from 'helpers/wait_for_promises';

jest.useFakeTimers();
jest.spyOn(global, 'setTimeout');

jest.mock('ee/saml_sso/saml_sessions', () => ({
  getExpiringSamlSession: jest.fn(),
}));

jest.mock('~/lib/utils/url_utility', () => ({
  refreshCurrentPage: jest.fn(),
}));

describe('SamlReloadModal', () => {
  let wrapper;

  const samlSessionsUrl = '/test.json';

  const createComponent = () => {
    wrapper = shallowMount(SamlReloadModal, {
      propsData: { samlProviderId: 1, samlSessionsUrl },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);

  describe('when there is no expiring SAML session', () => {
    it('does not show the modal', () => {
      createComponent();

      expect(findModal().props()).toMatchObject({
        visible: false,
        title: 'Your SAML session has expired',
        actionPrimary: {
          text: 'Reload page',
        },
        actionCancel: {
          text: 'Cancel',
        },
      });
      expect(findModal().attributes()).toMatchObject({
        'aria-live': 'assertive',
      });
    });
  });

  describe('when there is a expiring SAML sessions', () => {
    it('shows the modal', async () => {
      getExpiringSamlSession.mockResolvedValue({ timeRemainingMs: 1 });
      createComponent();

      await waitForPromises();
      jest.runAllTimers();
      expect(setTimeout).toHaveBeenCalledTimes(1);
      expect(setTimeout).toHaveBeenCalledWith(expect.any(Function), 1);
      await waitForPromises();

      expect(findModal().props('visible')).toBe(true);
    });

    it('triggers a refresh of the current page', () => {
      createComponent();

      findModal().vm.$emit('primary');
      expect(refreshCurrentPage).toHaveBeenCalled();
    });
  });
});

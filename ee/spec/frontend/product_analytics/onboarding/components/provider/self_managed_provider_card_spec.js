import { GlSprintf } from '@gitlab/ui';

import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import SelfManagedProviderCard from 'ee/product_analytics/onboarding/components/providers/self_managed_provider_card.vue';
import ProviderSettingsPreview from 'ee/product_analytics/onboarding/components/providers/provider_settings_preview.vue';
import {
  getEmptyProjectLevelAnalyticsProviderSettings,
  getPartialProjectLevelAnalyticsProviderSettings,
  getProjectLevelAnalyticsProviderSettings,
} from '../../../mock_data';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_action');

describe('SelfManagedProviderCard', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findProviderSettingsPreview = () => wrapper.findComponent(ProviderSettingsPreview);
  const findConnectSelfManagedProviderBtn = () =>
    wrapper.findByTestId('connect-your-own-provider-btn');

  const mockConfirmAction = (confirmed) => confirmAction.mockResolvedValueOnce(confirmed);

  const createWrapper = (provide = {}) => {
    wrapper = shallowMountExtended(SelfManagedProviderCard, {
      propsData: {
        projectAnalyticsSettingsPath: '/settings/analytics',
      },
      provide: {
        projectLevelAnalyticsProviderSettings: getProjectLevelAnalyticsProviderSettings(),
        ...provide,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const initProvider = () => {
    findConnectSelfManagedProviderBtn().vm.$emit('click');
    return waitForPromises();
  };

  describe('default behaviour', () => {
    beforeEach(() => createWrapper());

    it('should render a title and description', () => {
      expect(wrapper.text()).toContain('Self-managed provider');
      expect(wrapper.text()).toContain(
        'Manage your own analytics provider to process, store, and query analytics data.',
      );
    });
  });

  describe.each`
    scenario                                                | projectSettings
    ${'when no project provider settings are configured'}   | ${getEmptyProjectLevelAnalyticsProviderSettings()}
    ${'when some project provider settings are configured'} | ${getPartialProjectLevelAnalyticsProviderSettings()}
  `('$scenario', ({ projectSettings }) => {
    beforeEach(() => {
      return createWrapper({ projectLevelAnalyticsProviderSettings: projectSettings });
    });

    it('should not show summary of existing settings', () => {
      expect(findProviderSettingsPreview().exists()).toBe(false);
    });

    describe('when clicking setup', () => {
      it('should confirm with user that redirect to settings is required', async () => {
        mockConfirmAction(false);
        await initProvider();

        expect(confirmAction).toHaveBeenCalledWith(
          '',
          expect.objectContaining({
            primaryBtnText: 'Go to analytics settings',
            title: 'Connect your own provider',
            modalHtmlMessage: expect.stringContaining(
              `To connect your own provider, you'll be redirected`,
            ),
          }),
        );
      });

      it('should not emit "open-settings" event when user cancels', async () => {
        mockConfirmAction(false);
        await initProvider();

        expect(wrapper.emitted('open-settings')).toBeUndefined();
      });

      it('should emit "open-settings" event when confirmed', async () => {
        mockConfirmAction(true);
        await initProvider();

        expect(wrapper.emitted('open-settings')).toHaveLength(1);
      });
    });

    describe('when project settings are configured correctly', () => {
      beforeEach(() =>
        createWrapper({
          projectLevelAnalyticsProviderSettings: getProjectLevelAnalyticsProviderSettings(),
        }),
      );

      it('should show summary of existing settings', () => {
        expect(findProviderSettingsPreview().props()).toMatchObject({
          configuratorConnectionString: 'https://configurator.example.com',
          collectorHost: 'https://collector.example.com',
          cubeApiBaseUrl: 'https://cubejs.example.com',
          cubeApiKey: 'abc-123',
        });
      });

      describe('when selecting provider', () => {
        beforeEach(() => initProvider());

        it('should emit "confirm" event', () => {
          expect(wrapper.emitted('confirm')).toHaveLength(1);
        });
      });
    });
  });
});

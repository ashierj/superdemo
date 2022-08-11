import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createFlash from '~/flash';
import { updateGroupSettings } from 'ee/api/groups_api';
import SettingsForm from 'ee/admin/application_settings/reporting/git_abuse_settings/components/settings_form.vue';
import SettingsFormContainer from 'ee/group_settings/reporting/components/settings_form_container.vue';
import {
  SUCCESS_MESSAGE,
  SAVE_ERROR_MESSAGE,
} from 'ee/admin/application_settings/reporting/git_abuse_settings/constants';

jest.mock('ee/api/groups_api.js');
jest.mock('~/flash');

describe('SettingsFormContainer', () => {
  let wrapper;

  const GROUP_ID = 99;
  const MAX_DOWNLOADS = 10;
  const TIME_PERIOD = 300;
  const ALLOWLIST = ['user1', 'user2'];

  const createComponent = () => {
    wrapper = shallowMountExtended(SettingsFormContainer, {
      propsData: {
        groupId: GROUP_ID,
        maxDownloads: MAX_DOWNLOADS,
        timePeriod: TIME_PERIOD,
        allowlist: ALLOWLIST,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders SettingsForm with the correct props', () => {
    expect(wrapper.findComponent(SettingsForm).exists()).toEqual(true);
    expect(wrapper.findComponent(SettingsForm).props()).toMatchObject({
      isLoading: false,
      maxDownloads: MAX_DOWNLOADS,
      timePeriod: TIME_PERIOD,
      allowlist: ALLOWLIST,
    });
  });

  describe('when SettingsForm emits a "submit" event', () => {
    const payload = {
      maxDownloads: MAX_DOWNLOADS,
      timePeriod: TIME_PERIOD,
      allowlist: ALLOWLIST,
    };

    it('calls updateGroupSettings with the correct payload', () => {
      wrapper.findComponent(SettingsForm).vm.$emit('submit', payload);

      expect(updateGroupSettings).toHaveBeenCalledTimes(1);
      expect(updateGroupSettings).toHaveBeenCalledWith(GROUP_ID, {
        unique_project_download_limit: MAX_DOWNLOADS,
        unique_project_download_limit_interval_in_seconds: TIME_PERIOD,
        unique_project_download_limit_allowlist: ALLOWLIST,
      });
    });

    it('creates a flash with the correct message and type', async () => {
      wrapper.findComponent(SettingsForm).vm.$emit('submit', payload);

      await nextTick();

      expect(createFlash).toHaveBeenCalledWith({ message: SUCCESS_MESSAGE, type: 'notice' });
    });

    describe('updateGroupSettings fails', () => {
      it('creates a flash with the correct message and type', async () => {
        updateGroupSettings.mockImplementation(() => Promise.reject());

        wrapper.findComponent(SettingsForm).vm.$emit('submit', payload);

        await nextTick();

        expect(createFlash).toHaveBeenCalledWith({
          message: SAVE_ERROR_MESSAGE,
          captureError: true,
        });
      });
    });
  });
});

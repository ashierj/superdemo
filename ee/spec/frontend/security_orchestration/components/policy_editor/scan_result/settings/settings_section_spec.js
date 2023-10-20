import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  BLOCK_UNPROTECTING_BRANCHES,
  PREVENT_APPROVAL_BY_AUTHOR,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib/settings';
import SettingsSection from 'ee/security_orchestration/components/policy_editor/scan_result/settings/settings_section.vue';
import SettingsItem from 'ee/security_orchestration/components/policy_editor/scan_result/settings/settings_item.vue';

describe('SettingsSection', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(SettingsSection, {
      propsData,
      provide: {
        namespacePath: 'test-path',
      },
    });
  };

  const findAllSettingsItem = () => wrapper.findAllComponents(SettingsItem);
  const findProtectedBranchesSettingsItem = () =>
    wrapper.findByTestId('protected-branches-setting');
  const findMergeRequestSettingsItem = () => wrapper.findByTestId('merge-request-setting');

  describe('settings modification', () => {
    const createSettings = (value, key = BLOCK_UNPROTECTING_BRANCHES) => ({
      settings: {
        [key]: value,
      },
    });

    it.each`
      description                                         | propsData                                            | protectedBranchSettingVisible | mergeRequestSettingVisible
      ${`disable ${BLOCK_UNPROTECTING_BRANCHES} setting`} | ${createSettings(false)}                             | ${true}                       | ${false}
      ${`enable ${BLOCK_UNPROTECTING_BRANCHES} setting`}  | ${createSettings(true)}                              | ${true}                       | ${false}
      ${`disable ${PREVENT_APPROVAL_BY_AUTHOR} setting`}  | ${createSettings(false, PREVENT_APPROVAL_BY_AUTHOR)} | ${false}                      | ${true}
      ${`enable ${PREVENT_APPROVAL_BY_AUTHOR} setting`}   | ${createSettings(true, PREVENT_APPROVAL_BY_AUTHOR)}  | ${false}                      | ${true}
    `(
      '$description',
      ({ propsData, protectedBranchSettingVisible, mergeRequestSettingVisible }) => {
        createComponent({ propsData });
        expect(findProtectedBranchesSettingsItem().exists()).toBe(protectedBranchSettingVisible);
        expect(findMergeRequestSettingsItem().exists()).toBe(mergeRequestSettingVisible);
        expect(findAllSettingsItem().at(0).props('settings')).toEqual(propsData.settings);
      },
    );

    it('emits event when setting is toggled', async () => {
      createComponent({ propsData: createSettings(true) });

      await findAllSettingsItem()
        .at(0)
        .vm.$emit('update', { key: BLOCK_UNPROTECTING_BRANCHES, value: false });
      expect(wrapper.emitted('changed')).toEqual([[createSettings(false).settings]]);
    });

    it('should render different settings groups', () => {
      createComponent({
        propsData: {
          settings: {
            [BLOCK_UNPROTECTING_BRANCHES]: true,
            [PREVENT_APPROVAL_BY_AUTHOR]: true,
          },
        },
      });

      expect(findProtectedBranchesSettingsItem().exists()).toBe(true);
      expect(findMergeRequestSettingsItem().exists()).toBe(true);

      expect(findProtectedBranchesSettingsItem().props('link')).toBe(
        'http://test.host/test-path/-/settings/repository',
      );
      expect(findMergeRequestSettingsItem().props('link')).toBe(
        'http://test.host/test-path/-/settings/merge_requests',
      );
    });
  });
});

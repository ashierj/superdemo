import {
  PREVENT_APPROVAL_BY_AUTHOR,
  buildSettingsList,
  mergeRequestConfiguration,
  protectedBranchesConfiguration,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib/settings';

describe('approval_settings', () => {
  describe('buildSettingsList', () => {
    it('has defaults settings by default', () => {
      expect(buildSettingsList()).toEqual(protectedBranchesConfiguration);
    });

    it('has merge request settings by when flag is enabled', () => {
      expect(buildSettingsList({ hasAnyMergeRequestRule: true })).toEqual({
        ...protectedBranchesConfiguration,
        ...mergeRequestConfiguration,
      });
    });

    it('can update merge request settings', () => {
      const settings = {
        ...mergeRequestConfiguration,
        [PREVENT_APPROVAL_BY_AUTHOR]: false,
      };
      expect(buildSettingsList({ settings, hasAnyMergeRequestRule: true })).toEqual({
        ...protectedBranchesConfiguration,
        ...settings,
      });
    });

    it('has fall back values for approval settings', () => {
      const settings = {
        [PREVENT_APPROVAL_BY_AUTHOR]: true,
      };

      expect(buildSettingsList({ settings, hasAnyMergeRequestRule: true })).toEqual({
        ...protectedBranchesConfiguration,
        ...mergeRequestConfiguration,
      });
    });
  });
});

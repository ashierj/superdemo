import {
  PREVENT_APPROVAL_BY_AUTHOR,
  buildSettingsList,
  mergeRequestConfiguration,
  protectedBranchesConfiguration,
  pushingBranchesConfiguration,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib/settings';

afterEach(() => {
  window.gon = {};
});

describe('approval_settings', () => {
  describe('buildSettingsList', () => {
    it('returns the pushing branches settings by default', () => {
      expect(buildSettingsList()).toEqual(pushingBranchesConfiguration);
    });

    it('returns the protected branches settings when the "scanResultPoliciesBlockUnprotectingBranches" feature flag is enabled', () => {
      window.gon = { features: { scanResultPoliciesBlockUnprotectingBranches: true } };
      expect(buildSettingsList()).toEqual({
        ...pushingBranchesConfiguration,
        ...protectedBranchesConfiguration,
      });
    });

    it('returns merge request settings for the merge request rule', () => {
      expect(buildSettingsList({ hasAnyMergeRequestRule: true })).toEqual({
        ...pushingBranchesConfiguration,
        ...mergeRequestConfiguration,
      });
    });

    it('can update merge request settings', () => {
      window.gon = { features: { scanResultPoliciesBlockUnprotectingBranches: true } };
      const settings = {
        ...pushingBranchesConfiguration,
        ...mergeRequestConfiguration,
        [PREVENT_APPROVAL_BY_AUTHOR]: false,
      };
      expect(buildSettingsList({ settings, hasAnyMergeRequestRule: true })).toEqual({
        ...protectedBranchesConfiguration,
        ...settings,
      });
    });

    it('has fall back values for settings', () => {
      const settings = {
        [PREVENT_APPROVAL_BY_AUTHOR]: true,
      };

      expect(buildSettingsList({ settings, hasAnyMergeRequestRule: true })).toEqual({
        ...pushingBranchesConfiguration,
        ...mergeRequestConfiguration,
      });
    });
  });
});

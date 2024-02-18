import {
  createPolicyObject,
  fromYaml,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib';
import {
  collidingKeysScanResultManifest,
  mockDefaultBranchesScanResultManifest,
  mockDefaultBranchesScanResultObject,
  mockApprovalSettingsScanResultManifest,
  mockApprovalSettingsScanResultObject,
  mockApprovalSettingsPermittedInvalidScanResultManifest,
  mockApprovalSettingsPermittedInvalidScanResultObject,
  mockPolicyScopeScanResultManifest,
  mockPolicyScopeScanResultObject,
} from 'ee_jest/security_orchestration/mocks/mock_scan_result_policy_data';
import {
  unsupportedManifest,
  unsupportedManifestObject,
} from 'ee_jest/security_orchestration/mocks/mock_data';

afterEach(() => {
  window.gon = {};
});

jest.mock('lodash/uniqueId', () => jest.fn((prefix) => `${prefix}0`));

describe('fromYaml', () => {
  it.each`
    title                                                                                                | input                                                                    | output
    ${'returns the policy object for a supported manifest without approval_settings'}                    | ${{ manifest: mockDefaultBranchesScanResultManifest }}                   | ${mockDefaultBranchesScanResultObject}
    ${'returns the policy object for a supported manifest with approval_settings'}                       | ${{ manifest: mockApprovalSettingsScanResultManifest }}                  | ${mockApprovalSettingsScanResultObject}
    ${'returns the error object for a policy with an unsupported attribute'}                             | ${{ manifest: unsupportedManifest, validateRuleMode: true }}             | ${{ error: true }}
    ${'returns the error object for a policy with colliding self excluded keys'}                         | ${{ manifest: collidingKeysScanResultManifest, validateRuleMode: true }} | ${{ error: true }}
    ${'returns the policy object for a policy with an unsupported attribute when validation is skipped'} | ${{ manifest: unsupportedManifest }}                                     | ${unsupportedManifestObject}
  `('$title', ({ input, output }) => {
    expect(fromYaml(input)).toStrictEqual(output);
  });

  describe('feature flag', () => {
    it('returns the policy object for a manifest with "approval_settings" with the "scanResultPoliciesBlockUnprotectingBranches" feature flag on', () => {
      const input = { manifest: mockApprovalSettingsScanResultManifest, validateRuleMode: true };
      const output = mockApprovalSettingsScanResultObject;
      window.gon = { features: { scanResultPoliciesBlockUnprotectingBranches: true } };
      expect(fromYaml(input)).toStrictEqual(output);
    });

    it('returns the policy object for a manifest with "approval_settings" containing permitted invalid settings and the "scanResultPoliciesBlockUnprotectingBranches " feature flag on', () => {
      const input = {
        manifest: mockApprovalSettingsPermittedInvalidScanResultManifest,
        validateRuleMode: true,
      };
      const output = mockApprovalSettingsPermittedInvalidScanResultObject;
      window.gon = { features: { scanResultPoliciesBlockUnprotectingBranches: true } };
      expect(fromYaml(input)).toStrictEqual(output);
    });

    it('returns the policy object for a manifest with "approval_settings" containing permitted invalid settings and the "scanResultPoliciesBlockUnprotectingBranches " feature flag off', () => {
      const input = {
        manifest: mockApprovalSettingsPermittedInvalidScanResultManifest,
        validateRuleMode: true,
      };
      const output = mockApprovalSettingsPermittedInvalidScanResultObject;
      window.gon = { features: {} };
      expect(fromYaml(input)).toStrictEqual(output);
    });

    it('returns the policy object for a manifest with "approval_settings" with all feature flags off', () => {
      const input = { manifest: mockApprovalSettingsScanResultManifest, validateRuleMode: true };
      const output = mockApprovalSettingsScanResultObject;
      window.gon = { features: {} };
      expect(fromYaml(input)).toStrictEqual(output);
    });
  });
});

describe('createPolicyObject', () => {
  it.each`
    title                                                                          | input                                    | output
    ${'returns the policy object and no errors for a supported manifest'}          | ${mockDefaultBranchesScanResultManifest} | ${{ policy: mockDefaultBranchesScanResultObject, hasParsingError: false }}
    ${'returns the error policy object and the error for an unsupported manifest'} | ${unsupportedManifest}                   | ${{ policy: { error: true }, hasParsingError: true }}
    ${'returns the error policy object and the error for an colliding keys'}       | ${collidingKeysScanResultManifest}       | ${{ policy: { error: true }, hasParsingError: true }}
  `('$title', ({ input, output }) => {
    expect(createPolicyObject(input)).toStrictEqual(output);
  });

  describe('feature flag', () => {
    it.each`
      title                                                                                                                                                                              | features                                                 | input                                                     | output
      ${'returns the policy object for a manifest with `approval_settings` with the `scanResultPoliciesBlockUnprotectingBranches` feature flag on'}                                      | ${{ scanResultPoliciesBlockUnprotectingBranches: true }} | ${mockApprovalSettingsScanResultManifest}                 | ${{ policy: mockApprovalSettingsScanResultObject, hasParsingError: false }}
      ${'returns the policy object for a manifest with `approval_settings` containing permitted invalid settings and the `scanResultPoliciesBlockUnprotectingBranches` feature flag on'} | ${{ scanResultPoliciesBlockUnprotectingBranches: true }} | ${mockApprovalSettingsPermittedInvalidScanResultManifest} | ${{ policy: mockApprovalSettingsPermittedInvalidScanResultObject, hasParsingError: false }}
      ${'returns the policy object for a manifest with `policy_scope` feature flag on'}                                                                                                  | ${{ securityPoliciesPolicyScope: true }}                 | ${mockPolicyScopeScanResultManifest}                      | ${{ policy: mockPolicyScopeScanResultObject, hasParsingError: false }}
      ${'returns the policy object for a manifest with `policy_scope` feature flag on for project'}                                                                                      | ${{ securityPoliciesPolicyScopeProject: true }}          | ${mockPolicyScopeScanResultManifest}                      | ${{ policy: mockPolicyScopeScanResultObject, hasParsingError: false }}
      ${'returns the error object for a manifest with `approval_settings` containing permitted invalid settings and the `scanResultPoliciesBlockUnprotectingBranches` feature flag off'} | ${{}}                                                    | ${mockApprovalSettingsPermittedInvalidScanResultManifest} | ${{ policy: mockApprovalSettingsPermittedInvalidScanResultObject, hasParsingError: false }}
      ${'returns the policy object for a manifest with `approval_settings` with all feature flags off'}                                                                                  | ${{}}                                                    | ${mockApprovalSettingsScanResultManifest}                 | ${{ policy: mockApprovalSettingsScanResultObject, hasParsingError: false }}
      ${'returns the error object for a manifest with `policy_scope` feature flag off'}                                                                                                  | ${{}}                                                    | ${mockPolicyScopeScanResultManifest}                      | ${{ policy: { error: true }, hasParsingError: true }}
    `('$title', ({ features, input, output }) => {
      window.gon = { features };
      expect(createPolicyObject(input)).toStrictEqual(output);
    });
  });
});

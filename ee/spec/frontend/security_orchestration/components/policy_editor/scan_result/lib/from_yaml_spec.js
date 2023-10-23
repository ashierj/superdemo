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
} from 'ee_jest/security_orchestration/mocks/mock_scan_result_policy_data';
import {
  unsupportedManifest,
  unsupportedManifestObject,
} from 'ee_jest/security_orchestration/mocks/mock_data';

afterEach(() => {
  window.gon = {};
});

describe('fromYaml', () => {
  it.each`
    title                                                                                                | input                                                                    | output
    ${'returns the policy object for a supported manifest'}                                              | ${{ manifest: mockDefaultBranchesScanResultManifest }}                   | ${mockDefaultBranchesScanResultObject}
    ${'returns the error object for a policy with an unsupported attribute'}                             | ${{ manifest: unsupportedManifest, validateRuleMode: true }}             | ${{ error: true }}
    ${'returns the error object for a policy with colliding self excluded keys'}                         | ${{ manifest: collidingKeysScanResultManifest, validateRuleMode: true }} | ${{ error: true }}
    ${'returns the policy object for a policy with an unsupported attribute when validation is skipped'} | ${{ manifest: unsupportedManifest }}                                     | ${unsupportedManifestObject}
  `('$title', ({ input, output }) => {
    expect(fromYaml(input)).toStrictEqual(output);
  });

  describe('feature flag', () => {
    it.each`
      title                                                                                                                                                                                | features                                                 | input                                                                                           | output
      ${'returns the policy object for a manifest with `approval_settings` with the `scanResultPoliciesBlockUnprotectingBranches` feature flag on'}                                        | ${{ scanResultPoliciesBlockUnprotectingBranches: true }} | ${{ manifest: mockApprovalSettingsScanResultManifest, validateRuleMode: true }}                 | ${mockApprovalSettingsScanResultObject}
      ${'returns the policy object for a manifest with `approval_settings` containing permitted invalid settings and the `scanResultPoliciesBlockUnprotectingBranches ` feature flag on'}  | ${{ scanResultPoliciesBlockUnprotectingBranches: true }} | ${{ manifest: mockApprovalSettingsPermittedInvalidScanResultManifest, validateRuleMode: true }} | ${mockApprovalSettingsPermittedInvalidScanResultObject}
      ${'returns the policy object for a manifest with `approval_settings` containing permitted invalid settings and the `scanResultPoliciesBlockUnprotectingBranches ` feature flag off'} | ${{}}                                                    | ${{ manifest: mockApprovalSettingsPermittedInvalidScanResultManifest, validateRuleMode: true }} | ${mockApprovalSettingsPermittedInvalidScanResultObject}
      ${'returns the policy object for a manifest with `approval_settings` with the `scanResultAnyMergeRequest` feature flag on'}                                                          | ${{ scanResultAnyMergeRequest: true }}                   | ${{ manifest: mockApprovalSettingsScanResultManifest, validateRuleMode: true }}                 | ${mockApprovalSettingsScanResultObject}
      ${'returns the error object for a manifest with `approval_settings` with all feature flags off'}                                                                                     | ${{}}                                                    | ${{ manifest: mockApprovalSettingsScanResultManifest, validateRuleMode: true }}                 | ${{ error: true }}
    `('$title', ({ features, input, output }) => {
      window.gon = { features };
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
      ${'returns the error object for a manifest with `approval_settings` containing permitted invalid settings and the `scanResultPoliciesBlockUnprotectingBranches` feature flag off'} | ${{}}                                                    | ${mockApprovalSettingsPermittedInvalidScanResultManifest} | ${{ policy: mockApprovalSettingsPermittedInvalidScanResultObject, hasParsingError: false }}
      ${'returns the policy object for a manifest with `approval_settings` with the `scanResultAnyMergeRequest` feature flag on'}                                                        | ${{ scanResultAnyMergeRequest: true }}                   | ${mockApprovalSettingsScanResultManifest}                 | ${{ policy: mockApprovalSettingsScanResultObject, hasParsingError: false }}
      ${'returns the error object for a manifest with `approval_settings` with all feature flags off'}                                                                                   | ${{}}                                                    | ${mockApprovalSettingsScanResultManifest}                 | ${{ policy: { error: true }, hasParsingError: true }}
    `('$title', ({ features, input, output }) => {
      window.gon = { features };
      expect(createPolicyObject(input)).toStrictEqual(output);
    });
  });
});

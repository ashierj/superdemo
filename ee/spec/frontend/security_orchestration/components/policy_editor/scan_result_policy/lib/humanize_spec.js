import {
  humanizeRules,
  humanizeInvalidBranchesError,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib';
import {
  securityScanBuildRule,
  licenseScanBuildRule,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/rules';
import {
  ALL_PROTECTED_BRANCHES,
  HUMANIZED_BRANCH_TYPE_TEXT_DICT,
  INVALID_RULE_MESSAGE,
  NO_RULE_MESSAGE,
  PROJECT_DEFAULT_BRANCH,
} from 'ee/security_orchestration/components/policy_editor/constants';

jest.mock('~/locale', () => ({
  getPreferredLocales: jest.fn().mockReturnValue(['en']),
  sprintf: jest.requireActual('~/locale').sprintf,
  s__: jest.requireActual('~/locale').s__, // eslint-disable-line no-underscore-dangle
  n__: jest.requireActual('~/locale').n__, // eslint-disable-line no-underscore-dangle
  __: jest.requireActual('~/locale').__,
}));

const {
  branch_type: defaultSecurityScanBranchType,
  ...securityScanBuildRuleWithoutBranchType
} = securityScanBuildRule();

const {
  branch_type: defaultLicenseScanBranchType,
  ...licenseScanBuildRuleWithoutBranchType
} = licenseScanBuildRule();

const singleValuedSecurityScannerRule = {
  rule: {
    ...securityScanBuildRuleWithoutBranchType,
    branches: ['main'],
    scanners: ['sast'],
    severity_levels: ['critical'],
    vulnerability_states: ['newly_detected'],
  },
  humanized: {
    summary:
      'When SAST scanner finds any vulnerabilities in an open merge request targeting the main branch and all the following apply:',
    criteriaList: [
      'Severity is critical.',
      'Vulnerabilities are new and need triage or dismissed.',
    ],
  },
};

const noVulnerabilityStatesSecurityScannerRule = {
  rule: {
    ...securityScanBuildRuleWithoutBranchType,
    branches: ['main'],
    scanners: ['sast'],
    severity_levels: ['critical'],
  },
  humanized: {
    summary:
      'When SAST scanner finds any vulnerabilities in an open merge request targeting the main branch and all the following apply:',
    criteriaList: ['Severity is critical.'],
  },
};

const multipleValuedSecurityScannerRule = {
  rule: {
    ...securityScanBuildRuleWithoutBranchType,
    branches: ['staging', 'main'],
    scanners: ['dast', 'sast'],
    vulnerabilities_allowed: 2,
    severity_levels: ['info', 'critical'],
    vulnerability_states: ['resolved'],
  },
  humanized: {
    summary:
      'When DAST or SAST scanners find more than 2 vulnerabilities in an open merge request targeting the staging or main branches and all the following apply:',
    criteriaList: [
      'Severity is info or critical.',
      'Vulnerabilities are previously existing and resolved.',
    ],
  },
};

const noCriteriaSecurityScannerRule = {
  rule: {
    ...securityScanBuildRuleWithoutBranchType,
    branches: ['staging', 'main'],
    scanners: ['sast'],
    vulnerabilities_allowed: 1,
  },
  humanized: {
    summary:
      'When SAST scanner finds more than 1 vulnerability in an open merge request targeting the staging or main branches.',
    criteriaList: [],
  },
};

const branchTypeSecurityScannerRule = (branchType = PROJECT_DEFAULT_BRANCH.value) => ({
  rule: {
    ...securityScanBuildRule(),
    branch_type: branchType,
    severity_levels: [],
    vulnerability_states: [],
    scanners: ['sast'],
    vulnerabilities_allowed: 1,
  },
  humanized: {
    summary: `When SAST scanner finds more than 1 vulnerability in an open merge request targeting ${HUMANIZED_BRANCH_TYPE_TEXT_DICT[branchType]}.`,
    criteriaList: [],
  },
});

const invalidBranchTypeSecurityScannerRule = {
  rule: {
    ...securityScanBuildRule(),
    branch_type: 'invalid',
  },
  humanized: {
    summary: INVALID_RULE_MESSAGE,
  },
};

const branchTypeAndBranchesSecurityScannerRule = {
  rule: {
    ...securityScanBuildRule(),
    branch_type: PROJECT_DEFAULT_BRANCH.value,
  },
  humanized: {
    summary:
      'When any security scanner finds any vulnerabilities in an open merge request targeting the default branch.',
    criteriaList: [],
  },
};

const allValuedSecurityScannerRule = {
  rule: {
    ...securityScanBuildRule(),
    vulnerabilities_allowed: 2,
    severity_levels: ['info', 'critical'],
    vulnerability_states: ['new_needs_triage', 'resolved', 'confirmed'],
  },
  humanized: {
    summary:
      'When any security scanner finds more than 2 vulnerabilities in an open merge request targeting any protected branch and all the following apply:',
    criteriaList: [
      'Severity is info or critical.',
      'Vulnerabilities are new and need triage, or previously existing and resolved or confirmed.',
    ],
  },
};

const singleValuedLicenseScanRule = {
  rule: {
    ...licenseScanBuildRuleWithoutBranchType,
    branches: ['main'],
    license_types: ['MIT License'],
    license_states: ['detected'],
  },
  humanized: {
    summary:
      'When license scanner finds any license matching MIT License that is pre-existing and is in an open merge request targeting the main branch.',
  },
};

const multipleValuedLicenseScanRule = {
  rule: {
    ...licenseScanBuildRuleWithoutBranchType,
    branches: ['staging', 'main'],
    match_on_inclusion: false,
    license_types: ['CMU License', 'CNRI Jython License', 'CNRI Python License'],
    license_states: ['detected', 'newly_detected'],
  },
  humanized: {
    summary:
      'When license scanner finds any license except CMU License, CNRI Jython License and CNRI Python License in an open merge request targeting the staging or main branches.',
  },
};

const branchTypeLicenseScanRule = (branchType = PROJECT_DEFAULT_BRANCH.value) => ({
  rule: {
    ...licenseScanBuildRule(),
    branch_type: branchType,
    match_on_inclusion: false,
    license_types: ['CMU License', 'CNRI Jython License', 'CNRI Python License'],
    license_states: ['detected', 'newly_detected'],
  },
  humanized: {
    summary: `When license scanner finds any license except CMU License, CNRI Jython License and CNRI Python License in an open merge request targeting ${HUMANIZED_BRANCH_TYPE_TEXT_DICT[branchType]}.`,
  },
});

describe('humanizeRules', () => {
  it('returns the empty rules message in an Array if no rules are specified', () => {
    expect(humanizeRules([])).toStrictEqual([{ summary: NO_RULE_MESSAGE }]);
  });

  describe('security scanner rules', () => {
    it('returns a single rule as a human-readable string for user approvers only', () => {
      expect(humanizeRules([singleValuedSecurityScannerRule.rule])).toStrictEqual([
        singleValuedSecurityScannerRule.humanized,
      ]);
    });

    it('returns multiple rules with different number of branches/scanners as human-readable strings', () => {
      expect(
        humanizeRules([
          singleValuedSecurityScannerRule.rule,
          multipleValuedSecurityScannerRule.rule,
          noVulnerabilityStatesSecurityScannerRule.rule,
          noCriteriaSecurityScannerRule.rule,
        ]),
      ).toStrictEqual([
        singleValuedSecurityScannerRule.humanized,
        multipleValuedSecurityScannerRule.humanized,
        noVulnerabilityStatesSecurityScannerRule.humanized,
        noCriteriaSecurityScannerRule.humanized,
      ]);
    });

    it('returns a single rule as a human-readable string for all scanners and all protected branches', () => {
      expect(humanizeRules([allValuedSecurityScannerRule.rule])).toStrictEqual([
        allValuedSecurityScannerRule.humanized,
      ]);
    });

    it.each([PROJECT_DEFAULT_BRANCH.value, ALL_PROTECTED_BRANCHES.value])(
      'returns a single rule as a human-readable string for rules with branch type',
      (branchType) => {
        expect(humanizeRules([branchTypeSecurityScannerRule(branchType).rule])).toStrictEqual([
          branchTypeSecurityScannerRule(branchType).humanized,
        ]);
      },
    );

    it('returns a single rule as a human-readable string for rules with branch type and branches', () => {
      expect(humanizeRules([branchTypeAndBranchesSecurityScannerRule.rule])).toStrictEqual([
        branchTypeAndBranchesSecurityScannerRule.humanized,
      ]);
    });

    it('returns a default human-readable string for rules with invalid branch type', () => {
      expect(humanizeRules([invalidBranchTypeSecurityScannerRule.rule])).toStrictEqual([
        invalidBranchTypeSecurityScannerRule.humanized,
      ]);
    });
  });

  describe('license scanner rules', () => {
    it('returns a single rule as a human-readable string for user approvers only', () => {
      expect(humanizeRules([singleValuedLicenseScanRule.rule])).toStrictEqual([
        singleValuedLicenseScanRule.humanized,
      ]);
    });

    it('returns multiple rules with different number of branches/scanners as human-readable strings', () => {
      expect(
        humanizeRules([singleValuedLicenseScanRule.rule, multipleValuedLicenseScanRule.rule]),
      ).toStrictEqual([
        singleValuedLicenseScanRule.humanized,
        multipleValuedLicenseScanRule.humanized,
      ]);
    });

    it.each([PROJECT_DEFAULT_BRANCH.value, ALL_PROTECTED_BRANCHES.value])(
      'returns a single rule as a human-readable string for rules with branch type',
      (branchType) => {
        expect(humanizeRules([branchTypeLicenseScanRule(branchType).rule])).toStrictEqual([
          branchTypeLicenseScanRule(branchType).humanized,
        ]);
      },
    );
  });
});

describe('humanizeInvalidBranchesError', () => {
  it('returns message without any branch name for an empty array', () => {
    expect(humanizeInvalidBranchesError([])).toEqual(
      'The following branches do not exist on this development project: . Please review all protected branches to ensure the values are accurate before updating this policy.',
    );
  });

  it('returns message with a single branch name for an array with single element', () => {
    expect(humanizeInvalidBranchesError(['main'])).toEqual(
      'The following branches do not exist on this development project: main. Please review all protected branches to ensure the values are accurate before updating this policy.',
    );
  });

  it('returns message with multiple branch names for array with multiple elements', () => {
    expect(humanizeInvalidBranchesError(['main', 'protected', 'master'])).toEqual(
      'The following branches do not exist on this development project: main, protected and master. Please review all protected branches to ensure the values are accurate before updating this policy.',
    );
  });
});

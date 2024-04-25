import {
  DEFAULT_SCAN_RESULT_POLICY,
  DEFAULT_SCAN_RESULT_POLICY_WITH_FALLBACK,
  DEFAULT_SCAN_RESULT_POLICY_WITH_BOT_MESSAGE,
  DEFAULT_SCAN_RESULT_POLICY_WITH_BOT_MESSAGE_WITH_FALLBACK,
  DEFAULT_SCAN_RESULT_POLICY_WITH_SCOPE,
  DEFAULT_SCAN_RESULT_POLICY_WITH_SCOPE_WITH_FALLBACK,
  getPolicyYaml,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib';
import { isGroup } from 'ee/security_orchestration/components/utils';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

describe('getPolicyYaml', () => {
  it.each`
    namespaceType              | includeBotComment | includeFallback | expected
    ${NAMESPACE_TYPES.GROUP}   | ${true}           | ${true}         | ${DEFAULT_SCAN_RESULT_POLICY_WITH_SCOPE_WITH_FALLBACK}
    ${NAMESPACE_TYPES.GROUP}   | ${true}           | ${false}        | ${DEFAULT_SCAN_RESULT_POLICY_WITH_SCOPE}
    ${NAMESPACE_TYPES.GROUP}   | ${false}          | ${true}         | ${DEFAULT_SCAN_RESULT_POLICY_WITH_SCOPE_WITH_FALLBACK}
    ${NAMESPACE_TYPES.GROUP}   | ${false}          | ${false}        | ${DEFAULT_SCAN_RESULT_POLICY_WITH_SCOPE}
    ${NAMESPACE_TYPES.PROJECT} | ${true}           | ${true}         | ${DEFAULT_SCAN_RESULT_POLICY_WITH_BOT_MESSAGE_WITH_FALLBACK}
    ${NAMESPACE_TYPES.PROJECT} | ${true}           | ${false}        | ${DEFAULT_SCAN_RESULT_POLICY_WITH_BOT_MESSAGE}
    ${NAMESPACE_TYPES.PROJECT} | ${false}          | ${true}         | ${DEFAULT_SCAN_RESULT_POLICY_WITH_FALLBACK}
    ${NAMESPACE_TYPES.PROJECT} | ${false}          | ${false}        | ${DEFAULT_SCAN_RESULT_POLICY}
  `(
    'returns the yaml for the $namespaceType namespace and includeBotComment as $includeBotComment and includeFallback as $includeFallback',
    ({ namespaceType, includeBotComment, includeFallback, expected }) => {
      expect(
        getPolicyYaml({ isGroup: isGroup(namespaceType), includeBotComment, includeFallback }),
      ).toEqual(expected);
    },
  );
});

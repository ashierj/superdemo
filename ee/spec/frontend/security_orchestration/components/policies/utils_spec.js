import {
  validateSourceFilter,
  validateTypeFilter,
  extractTypeParameter,
  extractSourceParameter,
} from 'ee/security_orchestration/components/policies/utils';
import {
  POLICY_SOURCE_OPTIONS,
  POLICY_TYPE_FILTER_OPTIONS,
  PIPELINE_EXECUTION_FILTER_OPTION,
} from 'ee/security_orchestration/components/policies/constants';

describe('utils', () => {
  beforeEach(() => {
    window.gon.features = { pipelineExecutionPolicyType: false };
  });

  describe('validateSourceFilter', () => {
    it.each`
      value                                                  | valid
      ${POLICY_SOURCE_OPTIONS.ALL.value}                     | ${true}
      ${POLICY_SOURCE_OPTIONS.INHERITED.value}               | ${true}
      ${POLICY_SOURCE_OPTIONS.DIRECT.value}                  | ${true}
      ${'invalid key'}                                       | ${false}
      ${''}                                                  | ${false}
      ${undefined}                                           | ${false}
      ${null}                                                | ${false}
      ${{}}                                                  | ${false}
      ${0}                                                   | ${false}
      ${POLICY_SOURCE_OPTIONS.ALL.value.toLowerCase()}       | ${true}
      ${POLICY_SOURCE_OPTIONS.INHERITED.value.toLowerCase()} | ${true}
      ${POLICY_SOURCE_OPTIONS.DIRECT.value.toLowerCase()}    | ${true}
    `('should validate source filters', ({ value, valid }) => {
      expect(validateSourceFilter(value)).toBe(valid);
    });
  });

  describe('validateTypeFilter', () => {
    it.each`
      value                                                                      | valid    | features                                  | toggle
      ${POLICY_TYPE_FILTER_OPTIONS.ALL.value}                                    | ${true}  | ${{ pipelineExecutionPolicyType: false }} | ${true}
      ${POLICY_TYPE_FILTER_OPTIONS.SCAN_EXECUTION.value}                         | ${true}  | ${{ pipelineExecutionPolicyType: false }} | ${true}
      ${POLICY_TYPE_FILTER_OPTIONS.APPROVAL.value}                               | ${true}  | ${{ pipelineExecutionPolicyType: false }} | ${true}
      ${''}                                                                      | ${true}  | ${{ pipelineExecutionPolicyType: false }} | ${true}
      ${'invalid key'}                                                           | ${false} | ${{ pipelineExecutionPolicyType: false }} | ${true}
      ${undefined}                                                               | ${false} | ${{ pipelineExecutionPolicyType: false }} | ${true}
      ${null}                                                                    | ${false} | ${{ pipelineExecutionPolicyType: false }} | ${true}
      ${{}}                                                                      | ${false} | ${{ pipelineExecutionPolicyType: false }} | ${true}
      ${0}                                                                       | ${false} | ${{ pipelineExecutionPolicyType: false }} | ${true}
      ${POLICY_TYPE_FILTER_OPTIONS.ALL.value.toLowerCase()}                      | ${true}  | ${{ pipelineExecutionPolicyType: false }} | ${true}
      ${POLICY_TYPE_FILTER_OPTIONS.SCAN_EXECUTION.value.toLowerCase()}           | ${true}  | ${{ pipelineExecutionPolicyType: false }} | ${true}
      ${POLICY_TYPE_FILTER_OPTIONS.APPROVAL.value.toLowerCase()}                 | ${true}  | ${{ pipelineExecutionPolicyType: false }} | ${true}
      ${PIPELINE_EXECUTION_FILTER_OPTION.PIPELINE_EXECUTION.value.toLowerCase()} | ${false} | ${{ pipelineExecutionPolicyType: false }} | ${true}
      ${PIPELINE_EXECUTION_FILTER_OPTION.PIPELINE_EXECUTION.value.toLowerCase()} | ${true}  | ${{ pipelineExecutionPolicyType: true }}  | ${true}
      ${PIPELINE_EXECUTION_FILTER_OPTION.PIPELINE_EXECUTION.value.toLowerCase()} | ${false} | ${{ pipelineExecutionPolicyType: true }}  | ${false}
    `('should validate type filters', ({ value, valid, features, toggle }) => {
      window.gon.features = features;
      expect(validateTypeFilter(value, toggle)).toBe(valid);
    });
  });

  describe('extractTypeParameter', () => {
    it.each`
      type                                                             | output
      ${POLICY_TYPE_FILTER_OPTIONS.ALL.value}                          | ${''}
      ${POLICY_TYPE_FILTER_OPTIONS.SCAN_EXECUTION.value}               | ${'SCAN_EXECUTION'}
      ${POLICY_TYPE_FILTER_OPTIONS.APPROVAL.value}                     | ${'APPROVAL'}
      ${''}                                                            | ${''}
      ${'invalid key'}                                                 | ${''}
      ${undefined}                                                     | ${''}
      ${null}                                                          | ${''}
      ${{}}                                                            | ${''}
      ${0}                                                             | ${''}
      ${POLICY_TYPE_FILTER_OPTIONS.ALL.value.toLowerCase()}            | ${''}
      ${POLICY_TYPE_FILTER_OPTIONS.SCAN_EXECUTION.value.toLowerCase()} | ${'SCAN_EXECUTION'}
      ${POLICY_TYPE_FILTER_OPTIONS.APPROVAL.value.toLowerCase()}       | ${'APPROVAL'}
      ${'scan_result'}                                                 | ${'APPROVAL'}
    `('should extract valid type parameter', ({ type, output }) => {
      expect(extractTypeParameter(type)).toBe(output);
    });
  });

  describe('extractSourceParameter', () => {
    it.each`
      source                                                 | output
      ${POLICY_SOURCE_OPTIONS.ALL.value}                     | ${'INHERITED'}
      ${POLICY_SOURCE_OPTIONS.INHERITED.value}               | ${'INHERITED_ONLY'}
      ${POLICY_SOURCE_OPTIONS.DIRECT.value}                  | ${'DIRECT'}
      ${'invalid key'}                                       | ${'INHERITED'}
      ${''}                                                  | ${'INHERITED'}
      ${undefined}                                           | ${'INHERITED'}
      ${null}                                                | ${'INHERITED'}
      ${{}}                                                  | ${'INHERITED'}
      ${0}                                                   | ${'INHERITED'}
      ${POLICY_SOURCE_OPTIONS.ALL.value.toLowerCase()}       | ${'INHERITED'}
      ${POLICY_SOURCE_OPTIONS.INHERITED.value.toLowerCase()} | ${'INHERITED_ONLY'}
      ${POLICY_SOURCE_OPTIONS.DIRECT.value.toLowerCase()}    | ${'DIRECT'}
    `('should validate source filters', ({ source, output }) => {
      expect(extractSourceParameter(source)).toBe(output);
    });
  });
});

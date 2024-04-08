import {
  createPolicyObject,
  fromYaml,
  policyToYaml,
  toYaml,
} from 'ee/security_orchestration/components/policy_editor/pipeline_execution/utils';
import {
  customYaml,
  customYamlObject,
} from 'ee_jest/security_orchestration/mocks/mock_pipeline_execution_policy_data';

describe('fromYaml', () => {
  it.each`
    title                                                   | input                       | output              | features
    ${'returns the policy object for a supported manifest'} | ${{ manifest: customYaml }} | ${customYamlObject} | ${{}}
  `('$title', ({ input, output, features }) => {
    window.gon = { features };
    expect(fromYaml(input)).toStrictEqual(output);
  });
});

describe('createPolicyObject', () => {
  it.each`
    title                                                                 | input           | output
    ${'returns the policy object and no errors for a supported manifest'} | ${[customYaml]} | ${{ policy: customYamlObject, hasParsingError: false }}
  `('$title', ({ input, output }) => {
    expect(createPolicyObject(...input)).toStrictEqual(output);
  });
});

describe('policyToYaml', () => {
  it('returns policy object as yaml', () => {
    expect(policyToYaml(customYamlObject)).toBe(customYaml);
  });
});

describe('toYaml', () => {
  it('returns policy object as yaml', () => {
    expect(toYaml(customYamlObject)).toBe(customYaml);
  });
});

import {
  isPolicyInherited,
  policyHasNamespace,
  isDefaultMode,
  policyScopeHasExcludingProjects,
  policyScopeHasIncludingProjects,
  policyScopeProjectsKey,
  policyHasAllProjectsInGroup,
  policyScopeHasComplianceFrameworks,
  policyScopeProjectLength,
  policyScopeComplianceFrameworkIds,
} from 'ee/security_orchestration/components/utils';
import {
  EXCLUDING,
  INCLUDING,
} from 'ee/security_orchestration/components/policy_editor/scope/constants';

describe(isPolicyInherited, () => {
  it.each`
    input                   | output
    ${undefined}            | ${false}
    ${{}}                   | ${false}
    ${{ inherited: false }} | ${false}
    ${{ inherited: true }}  | ${true}
  `('returns `$output` when passed `$input`', ({ input, output }) => {
    expect(isPolicyInherited(input)).toBe(output);
  });
});

describe(policyHasNamespace, () => {
  it.each`
    input                              | output
    ${undefined}                       | ${false}
    ${{}}                              | ${false}
    ${{ namespace: undefined }}        | ${false}
    ${{ namespace: {} }}               | ${true}
    ${{ namespace: { name: 'name' } }} | ${true}
  `('returns `$output` when passed `$input`', ({ input, output }) => {
    expect(policyHasNamespace(input)).toBe(output);
  });
});

describe(isDefaultMode, () => {
  it.each`
    input                            | output
    ${undefined}                     | ${true}
    ${{}}                            | ${true}
    ${null}                          | ${true}
    ${{ compliance_frameworks: [] }} | ${false}
  `('returns `$output` when passed `$input`', ({ input, output }) => {
    expect(isDefaultMode(input)).toBe(output);
  });
});

describe(policyScopeHasExcludingProjects, () => {
  it.each`
    input                                                  | output
    ${undefined}                                           | ${false}
    ${{}}                                                  | ${false}
    ${null}                                                | ${false}
    ${{ compliance_frameworks: [] }}                       | ${false}
    ${{ projects: [] }}                                    | ${false}
    ${{ projects: { including: [] } }}                     | ${false}
    ${{ projects: { excluding: [] } }}                     | ${false}
    ${{ projects: { excluding: [{}] } }}                   | ${true}
    ${{ projects: { excluding: [undefined] } }}            | ${false}
    ${{ projects: { excluding: [{ id: 1 }, { id: 2 }] } }} | ${true}
  `('returns `$output` when passed `$input`', ({ input, output }) => {
    expect(policyScopeHasExcludingProjects(input)).toBe(output);
  });
});

describe(policyScopeHasIncludingProjects, () => {
  it.each`
    input                                                  | output
    ${undefined}                                           | ${false}
    ${{}}                                                  | ${false}
    ${null}                                                | ${false}
    ${{ compliance_frameworks: [] }}                       | ${false}
    ${{ projects: [] }}                                    | ${false}
    ${{ projects: { including: [] } }}                     | ${false}
    ${{ projects: { excluding: [] } }}                     | ${false}
    ${{ projects: { excluding: [{}] } }}                   | ${false}
    ${{ projects: { excluding: [undefined] } }}            | ${false}
    ${{ projects: { excluding: [{ id: 1 }, { id: 2 }] } }} | ${false}
    ${{ projects: { including: [undefined] } }}            | ${false}
    ${{ projects: { including: [{ id: 1 }, { id: 2 }] } }} | ${true}
  `('returns `$output` when passed `$input`', ({ input, output }) => {
    expect(policyScopeHasIncludingProjects(input)).toBe(output);
  });
});

describe(policyScopeProjectsKey, () => {
  it.each`
    input                                                  | output
    ${undefined}                                           | ${EXCLUDING}
    ${{}}                                                  | ${EXCLUDING}
    ${null}                                                | ${EXCLUDING}
    ${{ compliance_frameworks: [] }}                       | ${EXCLUDING}
    ${{ projects: [] }}                                    | ${EXCLUDING}
    ${{ projects: { including: [] } }}                     | ${EXCLUDING}
    ${{ projects: { excluding: [] } }}                     | ${EXCLUDING}
    ${{ projects: { excluding: [{ id: 1 }, { id: 2 }] } }} | ${EXCLUDING}
    ${{ projects: { including: [{ id: 1 }, { id: 2 }] } }} | ${INCLUDING}
  `('returns `$output` when passed `$input`', ({ input, output }) => {
    expect(policyScopeProjectsKey(input)).toBe(output);
  });
});

describe(policyHasAllProjectsInGroup, () => {
  it.each`
    input                                                  | output
    ${undefined}                                           | ${false}
    ${{}}                                                  | ${false}
    ${null}                                                | ${false}
    ${{ compliance_frameworks: [] }}                       | ${true}
    ${{ projects: [] }}                                    | ${true}
    ${{ projects: { including: [] } }}                     | ${true}
    ${{ projects: { excluding: [] } }}                     | ${true}
    ${{ projects: { excluding: [{}] } }}                   | ${false}
    ${{ projects: { excluding: [undefined] } }}            | ${true}
    ${{ projects: { excluding: [{ id: 1 }, { id: 2 }] } }} | ${false}
    ${{ projects: { including: [undefined] } }}            | ${true}
    ${{ projects: { including: [{ id: 1 }, { id: 2 }] } }} | ${true}
  `('returns `$output` when passed `$input`', ({ input, output }) => {
    expect(policyHasAllProjectsInGroup(input)).toBe(output);
  });
});

describe(policyScopeHasComplianceFrameworks, () => {
  it.each`
    input                                     | output
    ${undefined}                              | ${false}
    ${{}}                                     | ${false}
    ${null}                                   | ${false}
    ${{ compliance_frameworks: [] }}          | ${false}
    ${{ compliance_frameworks: [{}] }}        | ${true}
    ${{ compliance_frameworks: undefined }}   | ${false}
    ${{ compliance_frameworks: [{ id: 1 }] }} | ${true}
  `('returns `$output` when passed `$input`', ({ input, output }) => {
    expect(policyScopeHasComplianceFrameworks(input)).toBe(output);
  });
});

describe(policyScopeProjectLength, () => {
  it.each`
    input                                                  | output
    ${undefined}                                           | ${0}
    ${{}}                                                  | ${0}
    ${null}                                                | ${0}
    ${{ compliance_frameworks: [] }}                       | ${0}
    ${{ projects: { excluding: [undefined] } }}            | ${0}
    ${{ projects: { excluding: [{ id: 1 }, { id: 2 }] } }} | ${2}
    ${{ projects: { including: [undefined] } }}            | ${0}
    ${{ projects: { including: [{ id: 1 }, { id: 2 }] } }} | ${2}
  `('returns `$output` when passed `$input`', ({ input, output }) => {
    expect(policyScopeProjectLength(input)).toBe(output);
  });
});

describe(policyScopeComplianceFrameworkIds, () => {
  it.each`
    input                                                              | output
    ${undefined}                                                       | ${[]}
    ${{}}                                                              | ${[]}
    ${null}                                                            | ${[]}
    ${{ compliance_frameworks: [] }}                                   | ${[]}
    ${{ projects: { excluding: [{ id: 1 }, { id: 2 }] } }}             | ${[]}
    ${{ projects: { including: [{ id: 1 }, { id: 2 }] } }}             | ${[]}
    ${{ compliance_frameworks: [{ id: 1 }, { id: 2 }] }}               | ${[1, 2]}
    ${{ compliance_frameworks: [{ invalidId: 1 }, { invalidId: 2 }] }} | ${[]}
  `('returns `$output` when passed `$input`', ({ input, output }) => {
    expect(policyScopeComplianceFrameworkIds(input)).toEqual(output);
  });
});

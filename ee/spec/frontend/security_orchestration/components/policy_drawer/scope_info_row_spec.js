import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ScopeInfoRow from 'ee/security_orchestration/components/policy_drawer/scope_info_row.vue';
import ComplianceFrameworksToggleList from 'ee/security_orchestration/components/policy_drawer/compliance_frameworks_toggle_list.vue';
import ProjectsToggleList from 'ee/security_orchestration/components/policy_drawer/projects_toggle_list.vue';

describe('ScopeInfoRow', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(ScopeInfoRow, {
      propsData,
    });
  };

  const findComplianceFrameworksToggleList = () =>
    wrapper.findComponent(ComplianceFrameworksToggleList);
  const findProjectsToggleList = () => wrapper.findComponent(ProjectsToggleList);
  const findDefaultScopeText = () => wrapper.findByTestId('default-scope-text');
  const findPolicyScopeSection = () => wrapper.findByTestId('policy-scope');

  it(`renders policy scope for`, () => {
    createComponent();

    expect(findPolicyScopeSection().exists()).toBe(true);
    expect(findDefaultScopeText().exists()).toBe(true);
  });

  it('renders policy scope for compliance frameworks', () => {
    createComponent({
      propsData: {
        policyScope: {
          compliance_frameworks: [{ id: 1 }, { id: 2 }],
        },
      },
    });

    expect(findComplianceFrameworksToggleList().exists()).toBe(true);
    expect(findProjectsToggleList().exists()).toBe(false);
    expect(findComplianceFrameworksToggleList().props('complianceFrameworkIds')).toEqual([1, 2]);
  });

  it.each(['including', 'excluding'])('renders policy scope for projects', (type) => {
    createComponent({
      propsData: {
        policyScope: {
          projects: {
            [type]: [{ id: 1 }, { id: 2 }],
          },
        },
      },
    });

    expect(findComplianceFrameworksToggleList().exists()).toBe(false);
    expect(findProjectsToggleList().exists()).toBe(true);
    expect(findProjectsToggleList().props('projectIds')).toEqual([1, 2]);
  });

  it.each`
    policyScope
    ${{}}
    ${undefined}
    ${null}
    ${{ compliance_frameworks: [] }}
    ${{ projects: { including: [] } }}
    ${{ compliance_frameworks: undefined }}
    ${{ projects: { including: undefined } }}
    ${{ projects: { excluding: undefined } }}
    ${{ compliance_frameworks: null }}
    ${{ projects: { including: null } }}
    ${{ projects: { excluding: null } }}
    ${{ projects: {} }}
    ${{ projects: undefined }}
  `('renders fallback ui', ({ policyScope }) => {
    createComponent({
      propsData: {
        policyScope,
      },
    });

    expect(findDefaultScopeText().exists()).toBe(true);
    expect(findDefaultScopeText().text()).toBe('No scope');
  });
});

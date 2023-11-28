import { GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import ScopeSection from 'ee/security_orchestration/components/policy_editor/scope/scope_section.vue';
import ComplianceFrameworkDropdown from 'ee/security_orchestration/components/policy_editor/scope/compliance_framework_dropdown.vue';
import GroupProjectsDropdown from 'ee/security_orchestration/components/group_projects_dropdown.vue';
import {
  PROJECTS_WITH_FRAMEWORK,
  ALL_PROJECTS_IN_GROUP,
  SPECIFIC_PROJECTS,
  EXCEPT_PROJECTS,
} from 'ee/security_orchestration/components/policy_editor/scope/constants';

describe('PolicyScope', () => {
  let wrapper;

  const createComponent = ({ propsData } = {}) => {
    wrapper = shallowMountExtended(ScopeSection, {
      propsData: {
        policyScope: {},
        ...propsData,
      },
      provide: {
        namespacePath: 'gitlab-org',
        rootNamespacePath: 'gitlab-org',
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findComplianceFrameworkDropdown = () => wrapper.findComponent(ComplianceFrameworkDropdown);
  const findGroupProjectsDropdown = () => wrapper.findComponent(GroupProjectsDropdown);
  const findProjectScopeTypeDropdown = () => wrapper.findByTestId('project-scope-type');
  const findExceptionTypeDropdown = () => wrapper.findByTestId('exception-type');

  beforeEach(() => {
    createComponent();
  });

  it('should render framework dropdown in initial state', () => {
    expect(findProjectScopeTypeDropdown().props('selected')).toBe(PROJECTS_WITH_FRAMEWORK);
    expect(findComplianceFrameworkDropdown().exists()).toBe(true);

    expect(findExceptionTypeDropdown().exists()).toBe(false);
    expect(findGroupProjectsDropdown().exists()).toBe(false);
    expect(findGlAlert().exists()).toBe(false);
  });

  it('should change scope and reset it', async () => {
    await findProjectScopeTypeDropdown().vm.$emit('select', ALL_PROJECTS_IN_GROUP);

    expect(findComplianceFrameworkDropdown().exists()).toBe(false);

    expect(findExceptionTypeDropdown().exists()).toBe(true);
    expect(findGroupProjectsDropdown().exists()).toBe(false);
    expect(wrapper.emitted('changed')).toEqual([
      [
        {
          projects: {
            excluding: [],
          },
        },
      ],
    ]);

    await findProjectScopeTypeDropdown().vm.$emit('select', SPECIFIC_PROJECTS);

    expect(findExceptionTypeDropdown().exists()).toBe(false);
    expect(findGroupProjectsDropdown().exists()).toBe(true);
    expect(wrapper.emitted('changed')).toEqual([
      [
        {
          projects: {
            excluding: [],
          },
        },
      ],
      [
        {
          projects: {
            including: [],
          },
        },
      ],
    ]);
  });

  it('should select excluding projects', async () => {
    await findProjectScopeTypeDropdown().vm.$emit('select', ALL_PROJECTS_IN_GROUP);

    expect(findGroupProjectsDropdown().exists()).toBe(false);

    await findExceptionTypeDropdown().vm.$emit('select', EXCEPT_PROJECTS);

    expect(findGroupProjectsDropdown().exists()).toBe(true);

    findGroupProjectsDropdown().vm.$emit('select', [
      { id: convertToGraphQLId(TYPENAME_PROJECT, '1') },
      { id: convertToGraphQLId(TYPENAME_PROJECT, '2') },
    ]);

    expect(wrapper.emitted('changed')).toEqual([
      [
        {
          projects: {
            excluding: [],
          },
        },
      ],
      [
        {
          projects: {
            excluding: [],
          },
        },
      ],
      [{ projects: { excluding: [{ id: 1 }, { id: 2 }] } }],
    ]);
  });

  it('should select including projects', async () => {
    await findProjectScopeTypeDropdown().vm.$emit('select', SPECIFIC_PROJECTS);

    expect(findGroupProjectsDropdown().exists()).toBe(true);

    findGroupProjectsDropdown().vm.$emit('select', [
      { id: convertToGraphQLId(TYPENAME_PROJECT, '1') },
      { id: convertToGraphQLId(TYPENAME_PROJECT, '2') },
    ]);

    expect(wrapper.emitted('changed')).toEqual([
      [
        {
          projects: {
            including: [],
          },
        },
      ],
      [{ projects: { including: [{ id: 1 }, { id: 2 }] } }],
    ]);
  });

  it('should select compliance frameworks', () => {
    findComplianceFrameworkDropdown().vm.$emit('select', ['id1', 'id2']);

    expect(wrapper.emitted('changed')).toEqual([
      [{ compliance_frameworks: [{ id: 'id1' }, { id: 'id2' }] }],
    ]);
  });

  describe('existing policy scope', () => {
    it('should render existing compliance frameworks', () => {
      createComponent({
        propsData: {
          policyScope: {
            compliance_frameworks: [{ id: 'id1' }, { id: 'id2' }],
          },
        },
      });

      expect(findComplianceFrameworkDropdown().exists()).toBe(true);
      expect(findComplianceFrameworkDropdown().props('selectedFrameworkIds')).toEqual([
        'id1',
        'id2',
      ]);

      expect(findExceptionTypeDropdown().exists()).toBe(false);
      expect(findGroupProjectsDropdown().exists()).toBe(false);
    });

    it('should render existing excluding projects', () => {
      createComponent({
        propsData: {
          policyScope: {
            projects: {
              excluding: [{ id: 'id1' }, { id: 'id2' }],
            },
          },
        },
      });

      expect(findComplianceFrameworkDropdown().exists()).toBe(false);

      expect(findExceptionTypeDropdown().props('selected')).toBe(EXCEPT_PROJECTS);
      expect(findExceptionTypeDropdown().exists()).toBe(true);
      expect(findGroupProjectsDropdown().exists()).toBe(true);
      expect(findGroupProjectsDropdown().props('selected')).toEqual([
        convertToGraphQLId(TYPENAME_PROJECT, 'id1'),
        convertToGraphQLId(TYPENAME_PROJECT, 'id2'),
      ]);
    });

    it('should render existing including projects', () => {
      createComponent({
        propsData: {
          policyScope: {
            projects: {
              including: [{ id: 'id1' }, { id: 'id2' }],
            },
          },
        },
      });

      expect(findComplianceFrameworkDropdown().exists()).toBe(false);
      expect(findExceptionTypeDropdown().exists()).toBe(false);
      expect(findGroupProjectsDropdown().exists()).toBe(true);
      expect(findGroupProjectsDropdown().props('selected')).toEqual([
        convertToGraphQLId(TYPENAME_PROJECT, 'id1'),
        convertToGraphQLId(TYPENAME_PROJECT, 'id2'),
      ]);
    });

    it('should render alert message for projects dropdown', async () => {
      createComponent({
        propsData: {
          policyScope: {
            projects: {
              including: [{ id: 'id1' }, { id: 'id2' }],
            },
          },
        },
      });

      await findGroupProjectsDropdown().vm.$emit('projects-query-error');
      expect(findGlAlert().exists()).toBe(true);
    });

    it('should render alert message for compliance framework dropdown', async () => {
      await findComplianceFrameworkDropdown().vm.$emit('framework-query-error');
      expect(findGlAlert().exists()).toBe(true);
    });
  });
});

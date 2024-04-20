import { GlLabel, GlLink, GlAccordionItem, GlTruncate } from '@gitlab/ui';
import FrameworkInfoDrawer from 'ee/compliance_dashboard/components/frameworks_report/framework_info_drawer.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createFramework } from 'ee_jest/compliance_dashboard/mock_data';

describe('FrameworkInfoDrawer component', () => {
  let wrapper;

  const GROUP_PATH = 'foo';

  const defaultFramework = createFramework({ id: 1, isDefault: true, projects: 3 });
  const nonDefaultFramework = createFramework({ id: 2 });
  const associatedProjectsCount = defaultFramework.projects.nodes.length;
  const policiesCount =
    defaultFramework.scanExecutionPolicies.nodes.length +
    defaultFramework.scanResultPolicies.nodes.length;

  const findDefaultBadge = () => wrapper.findComponent(GlLabel);
  const findAccordionItems = () => wrapper.findAllComponents(GlAccordionItem);
  const findProjectLinks = () => findAccordionItems().at(1).findAllComponents(GlLink);
  const findPoliciesLinks = () => findAccordionItems().at(2).findAllComponents(GlLink);
  const findTitle = () => wrapper.findComponent(GlTruncate);
  const findEditFrameworkBtn = () => wrapper.findByText('Edit framework');

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(FrameworkInfoDrawer, {
      propsData: {
        showDrawer: true,
        ...props,
      },
      provide,
    });
  };

  describe('default framework display', () => {
    beforeEach(() => {
      createComponent({
        props: {
          groupPath: GROUP_PATH,
          framework: defaultFramework,
        },
        provide: {
          groupSecurityPoliciesPath: '/group-policies',
        },
      });
    });

    describe('for drawer body content', () => {
      it('renders the title', () => {
        expect(findTitle().props()).toMatchObject({ text: defaultFramework.name, position: 'end' });
      });

      it('renders the default badge', () => {
        expect(findDefaultBadge().exists()).toBe(true);
      });

      it('renders the edit framework button', () => {
        expect(findEditFrameworkBtn().exists()).toBe(true);
      });

      it('renders the Description accordion', () => {
        expect(findAccordionItems().at(0).props('title')).toBe(`Description`);
        expect(findAccordionItems().at(0).text()).toBe(defaultFramework.description);
      });

      it('renders the Associated Projects accordion', () => {
        expect(findAccordionItems().at(1).props('title')).toBe(
          `Associated Projects (${associatedProjectsCount})`,
        );
      });

      it('renders the Associated Projects list', () => {
        expect(findProjectLinks().exists()).toBe(true);
        expect(findProjectLinks().wrappers).toHaveLength(3);
        expect(findProjectLinks().at(0).text()).toContain(defaultFramework.projects.nodes[0].name);
        expect(findProjectLinks().at(0).attributes('href')).toBe(
          defaultFramework.projects.nodes[0].webUrl,
        );
      });

      it('renders the Policies accordion', () => {
        expect(findAccordionItems().at(2).props('title')).toBe(`Policies (${policiesCount})`);
      });

      it('renders the Policies list', () => {
        expect(findPoliciesLinks().exists()).toBe(true);
        expect(findPoliciesLinks().wrappers).toHaveLength(policiesCount);
        expect(findPoliciesLinks().at(0).attributes('href')).toBe(
          `/group-policies/${defaultFramework.scanResultPolicies.nodes[0].name}/edit?type=approval_policy`,
        );
      });
    });
  });

  describe('framework display', () => {
    beforeEach(() => {
      createComponent({
        props: {
          framework: nonDefaultFramework,
          groupPath: GROUP_PATH,
        },
        provide: {
          groupSecurityPoliciesPath: '/group-policies',
        },
      });
    });

    describe('for drawer body content', () => {
      it('does not renders the default badge', () => {
        expect(findDefaultBadge().exists()).toBe(false);
      });
    });
  });
});

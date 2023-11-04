import { GlLabel, GlLink, GlAccordionItem, GlTruncate } from '@gitlab/ui';
import FrameworkInfoDrawer from 'ee/compliance_dashboard/components/frameworks_report/framework_info_drawer.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createFrameworkReportFramework } from 'ee_jest/compliance_dashboard/mock_data';

describe('FrameworkInfoDrawer component', () => {
  let wrapper;

  const defaultFramework = createFrameworkReportFramework({ id: 1, isDefault: true });
  const nonDefaultFramework = createFrameworkReportFramework(2);
  const associatedProjectsCount = defaultFramework.associatedProjects.length;

  const findDefaultBadge = () => wrapper.findComponent(GlLabel);
  const findProjectLinks = () => wrapper.findAllComponents(GlLink);
  const findAccordionItems = () => wrapper.findAllComponents(GlAccordionItem);
  const findTitle = () => wrapper.findComponent(GlTruncate);
  const findEditFrameworkBtn = () => wrapper.findByText('Edit framework');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(FrameworkInfoDrawer, {
      propsData: {
        showDrawer: true,
        ...props,
      },
    });
  };

  describe('default framework display', () => {
    beforeEach(() => {
      createComponent({
        props: {
          framework: defaultFramework,
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
        expect(findProjectLinks().at(0).text()).toContain(
          defaultFramework.associatedProjects[0].name,
        );
        expect(findProjectLinks().at(0).attributes('href')).toBe(
          defaultFramework.associatedProjects[0].webUrl,
        );
      });
    });
  });

  describe('framework display', () => {
    beforeEach(() => {
      createComponent({
        props: {
          framework: nonDefaultFramework,
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

import { GlLabel } from '@gitlab/ui';
import FrameworkInfoDrawer from 'ee/compliance_dashboard/components/frameworks_report/framework_info_drawer.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createFramework } from 'ee_jest/compliance_dashboard/mock_data';

describe('FrameworkInfoDrawer component', () => {
  let wrapper;

  const defaultFramework = createFramework({ id: 1, isDefault: true });
  const nonDefaultFramework = createFramework(2);

  const findDefaultBadge = () => wrapper.findComponent(GlLabel);
  const findEditFrameworkBtn = () => wrapper.findByText('Edit framework');
  const findAssociatedProjectsTitle = () => wrapper.findByText('Associated Projects');

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
      it('renders the `requirement` title', () => {
        expect(wrapper.findByText(defaultFramework.name).exists()).toBe(true);
      });

      it('renders the default badge', () => {
        expect(findDefaultBadge().exists()).toBe(true);
      });

      it('renders the edit framework button', () => {
        expect(findEditFrameworkBtn().exists()).toBe(true);
      });

      it('renders the Associated Projects Title', () => {
        expect(findAssociatedProjectsTitle().exists()).toBe(true);
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

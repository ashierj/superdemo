import { GlTabs, GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CiResourceDetails from 'ee/ci/catalog/components/details/ci_resource_details.vue';
import CiResourceReadme from 'ee/ci/catalog/components/details/ci_resource_readme.vue';

describe('CiResourceDetails', () => {
  let wrapper;

  const defaultProps = {
    resourceId: 'gid://gitlab/Ci::Catalog::Resource/1',
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(CiResourceDetails, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlTabs,
      },
    });
  };
  const findAllTabs = () => wrapper.findAllComponents(GlTab);
  const findCiResourceReadme = () => wrapper.findComponent(CiResourceReadme);

  beforeEach(() => {
    createComponent();
  });

  describe('tabs', () => {
    it('renders the right number of tabs', () => {
      expect(findAllTabs()).toHaveLength(1);
    });

    it('renders the readme tab as default', () => {
      expect(findCiResourceReadme().exists()).toBe(true);
    });

    it('passes lazy attribute to all tabs', () => {
      findAllTabs().wrappers.forEach((tab) => {
        expect(tab.attributes().lazy).not.toBeUndefined();
      });
    });

    describe('readme tab', () => {
      it('passes the right props to the readme component', () => {
        expect(findCiResourceReadme().props().resourceId).toBe(defaultProps.resourceId);
      });
    });
  });
});

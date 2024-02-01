import { shallowMount } from '@vue/test-utils';
import Details from 'ee_component/packages_and_registries/google_artifact_registry/pages/details.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

describe('Details', () => {
  let wrapper;

  const breadCrumbState = {
    updateName: jest.fn(),
  };

  const provide = {
    breadCrumbState,
  };

  function createComponent({
    image = 'alpine@sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
  } = {}) {
    wrapper = shallowMount(Details, {
      provide,
      mocks: {
        $route: {
          params: {
            image,
          },
        },
      },
    });
  }

  const findTitleArea = () => wrapper.findComponent(TitleArea);

  describe('title area component', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the title', () => {
      expect(findTitleArea().props('title')).toBe('alpine@1234567890ab');
    });
  });

  it('calls the appropriate function to set the breadcrumbState', () => {
    createComponent();

    expect(breadCrumbState.updateName).toHaveBeenCalledWith('alpine@1234567890ab');
  });
});

import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ToggleList from 'ee/security_orchestration/components/policy_drawer/toggle_list.vue';

const MOCK_BRANCH_EXCEPTIONS = (count = 10) =>
  [...Array(count).keys()].map((i) => `test=list-${i}`);

describe('ToggleList', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(ToggleList, {
      propsData: {
        items: MOCK_BRANCH_EXCEPTIONS(),
        ...propsData,
      },
    });
  };

  const findToggleButton = () => wrapper.findComponent(GlButton);
  const findAllBranchExceptions = () => wrapper.findAllByTestId('list-item');
  const findExceptionList = () => wrapper.findByTestId('items-list');

  describe('initial state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should hide extra exceptions when length is over 5', () => {
      expect(findToggleButton().exists()).toBe(true);
      expect(findToggleButton().text()).toBe('+ 5 more');
      expect(findAllBranchExceptions()).toHaveLength(5);
      expect(findExceptionList().classes()).toContain('gl-list-style-none');
    });

    it('should show all branches when show all is clicked', async () => {
      expect(findAllBranchExceptions()).toHaveLength(5);

      findToggleButton().vm.$emit('click');
      await nextTick();

      expect(findAllBranchExceptions()).toHaveLength(10);
      expect(findToggleButton().text()).toBe('Hide extra items');
    });
  });

  describe('custom text', () => {
    it('should render custom button text', () => {
      createComponent({
        propsData: {
          customButtonText: 'Hide custom items',
        },
      });
      expect(findAllBranchExceptions()).toHaveLength(5);
      expect(findToggleButton().text()).toBe('Hide custom items');
    });

    it('should render custom close button text', async () => {
      createComponent({
        propsData: {
          customCloseButtonText: 'Hide custom items',
        },
      });

      await findToggleButton().vm.$emit('click');

      expect(findToggleButton().text()).toBe('Hide custom items');
      expect(wrapper.emitted('load-next-page')).toBeUndefined();
    });
  });

  describe('without pagination', () => {
    it('should not render toggle button when there are less than 5 exceptions', () => {
      createComponent({
        propsData: {
          items: MOCK_BRANCH_EXCEPTIONS(3),
        },
      });

      expect(findAllBranchExceptions()).toHaveLength(3);
      expect(findToggleButton().exists()).toBe(false);
    });

    it('should render bullet style lists', () => {
      createComponent({
        propsData: {
          bulletStyle: true,
        },
      });

      expect(findExceptionList().classes()).not.toContain('gl-list-style-none');
    });
  });

  describe('with pagination', () => {
    it('should emit load more pages event', () => {
      createComponent({
        propsData: {
          hasNextPage: true,
          items: MOCK_BRANCH_EXCEPTIONS(20),
        },
      });

      expect(findAllBranchExceptions()).toHaveLength(5);
      expect(findToggleButton().text()).toBe('+ 15 more');

      findToggleButton().vm.$emit('click');

      expect(wrapper.emitted('load-next-page')).toHaveLength(1);
    });

    it('should render hide button when last page is reached', () => {
      createComponent({
        propsData: {
          hasNextPage: false,
          items: MOCK_BRANCH_EXCEPTIONS(20),
          page: 4,
        },
      });

      expect(findAllBranchExceptions()).toHaveLength(20);
      expect(findToggleButton().text()).toBe('Hide extra items');

      findToggleButton().vm.$emit('click');

      expect(wrapper.emitted('load-next-page')).toBeUndefined();
    });
  });
});

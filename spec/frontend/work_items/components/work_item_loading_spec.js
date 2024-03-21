import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemLoading from '~/work_items/components/work_item_loading.vue';

describe('Work Item Loading spec', () => {
  let wrapper;

  const findWorkItemTwoColumnLoading = () => wrapper.findByTestId('work-item-two-column-loading');
  const findWorkItemSingleColumnLoading = () =>
    wrapper.findByTestId('work-item-single-column-loading');
  const findWorkItemTitleMetaLoading = () => wrapper.findByTestId('work-title-and-meta-loading');
  const findWorkItemDescriptionLoading = () =>
    wrapper.findByTestId('work-item-description-loading');
  const findWorkItemAttributesXsSmLoading = () =>
    wrapper.findByTestId('work-item-attributes-xssm-loading');
  const findWorkItemAttributesMdUpLoading = () =>
    wrapper.findByTestId('work-item-attributes-mdup-loading');
  const findWorkItemActivityPlaceholder = () =>
    wrapper.findByTestId('work-item-activity-placeholder-loading');
  const findWorkItemNotesLoading = () => wrapper.findByTestId('work-item-notes-loading');
  const findLoaders = () => findWorkItemAttributesXsSmLoading().findAllComponents(GlSkeletonLoader);

  const createComponent = ({ twoColumnView = false } = {}) => {
    wrapper = shallowMountExtended(WorkItemLoading, {
      propsData: {
        twoColumnView,
      },
    });
  };

  describe('Work Item Single Column loading view', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the single column loading', () => {
      expect(findWorkItemSingleColumnLoading().exists()).toBe(true);
      expect(findWorkItemTwoColumnLoading().exists()).toBe(false);
    });
  });

  describe('Work Item Two Column loading view', () => {
    beforeEach(() => {
      createComponent({ twoColumnView: true });
    });

    it('renders the two column loading', () => {
      expect(findWorkItemTwoColumnLoading().exists()).toBe(true);
    });

    it('renders the title and meta loading skeleton', () => {
      expect(findWorkItemTitleMetaLoading().exists()).toBe(true);
    });

    it('renders the description loading skeleton', () => {
      expect(findWorkItemDescriptionLoading().exists()).toBe(true);
    });

    it('renders the attributes loading skeleton', () => {
      expect(findWorkItemAttributesXsSmLoading().exists()).toBe(true);
      expect(findWorkItemAttributesMdUpLoading().exists()).toBe(true);
      expect(findLoaders()).toHaveLength(WorkItemLoading.loader.attributesRepeat);
    });

    it('renders the activity placeholder loading skeleton', () => {
      expect(findWorkItemActivityPlaceholder().exists()).toBe(true);
    });

    it('renders the notes loading skeleton', () => {
      expect(findWorkItemNotesLoading().exists()).toBe(true);
    });
  });
});

import { shallowMount } from '@vue/test-utils';
import { GlCollapse, GlButton } from '@gitlab/ui';
import WorkloadDetailsItem from '~/kubernetes_dashboard/components/workload_details_item.vue';

let wrapper;

const propsData = {
  label: 'name',
};
const defaultSlots = {
  default: '<b>slot value</b>',
  label: `<label>${propsData.label}</label>`,
};

const createWrapper = ({ collapsible, slots = defaultSlots } = {}) => {
  wrapper = shallowMount(WorkloadDetailsItem, {
    propsData: {
      ...propsData,
      collapsible,
    },
    slots,
  });
};

const findLabel = () => wrapper.findComponent('label');
const findCollapsible = () => wrapper.findComponent(GlCollapse);
const findCollapsibleButton = () => wrapper.findComponent(GlButton);

describe('Workload details item component', () => {
  beforeEach(() => {
    createWrapper();
  });

  describe('by default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the correct label', () => {
      expect(findLabel().text()).toBe(propsData.label);
    });

    it('renders default slot content', () => {
      expect(wrapper.html()).toContain(defaultSlots.default);
    });
  });

  describe('when collapsible is true', () => {
    beforeEach(() => {
      createWrapper({ collapsible: true });
    });

    it('renders collapsible component that is not visible', () => {
      expect(findCollapsible().props('visible')).toBe(false);
    });

    it('renders the collapsible button component', () => {
      expect(findCollapsibleButton().props('icon')).toBe('chevron-right');
      expect(findCollapsibleButton().attributes('aria-label')).toBe('Expand');
    });

    describe('when expanded', () => {
      beforeEach(() => {
        findCollapsibleButton().vm.$emit('click');
      });

      it('collapsible is visible', () => {
        expect(findCollapsible().props('visible')).toBe(true);
      });

      it('updates the collapsible button component', () => {
        expect(findCollapsibleButton().props('icon')).toBe('chevron-down');
        expect(findCollapsibleButton().attributes('aria-label')).toBe('Collapse');
      });

      it('renders default slot content inside the collapsible', () => {
        expect(findCollapsible().html()).toContain(defaultSlots.default);
      });
    });
  });

  describe('when label slot is provided', () => {
    const labelSlot = '<span>custom value</span>';

    beforeEach(() => {
      createWrapper({ slots: { label: labelSlot } });
    });

    it('renders label slot content', () => {
      expect(wrapper.html()).toContain(labelSlot);
    });
  });
});

import { GlCollapse } from '@gitlab/ui';
import EditSection from 'ee/compliance_dashboard/components/frameworks_report/edit_framework/components/edit_section.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('Section', () => {
  let wrapper;

  const findCollapse = () => wrapper.findComponent(GlCollapse);
  const findButton = (text) => wrapper.findByText(text);

  function createComponent(propsData = {}) {
    return mountExtended(EditSection, {
      propsData: {
        title: 'Foo',
        description: 'Bar',
        ...propsData,
      },
    });
  }

  describe('if not expandable', () => {
    beforeEach(() => {
      wrapper = createComponent({ expandable: false });
    });

    it('renders collapse expanded', () => {
      expect(findCollapse().props('visible')).toBe(true);
    });

    it('does not render expand/collapse button', () => {
      expect(findButton('Expand').exists()).toBe(false);
    });
  });

  describe('if expandable', () => {
    beforeEach(() => {
      wrapper = createComponent({ expandable: true });
    });

    it('renders collapse hidden by default', () => {
      expect(findCollapse().props('visible')).toBe(false);
    });

    it('renders expand button', () => {
      expect(findButton('Expand').exists()).toBe(true);
    });

    it('expands collapse on clicking button', async () => {
      await findButton('Expand').trigger('click');
      expect(findCollapse().props('visible')).toBe(true);
      expect(findButton('Expand').exists()).toBe(false);
      expect(findButton('Collapse').exists()).toBe(true);
    });
  });
});

import { shallowMount } from '@vue/test-utils';
import { GlCollapsibleListbox } from '@gitlab/ui';
import CodeBlockOverrideSelector from 'ee/security_orchestration/components/policy_editor/scan_execution/action/code_block_override_selector.vue';
import {
  INJECT,
  OVERRIDE,
  CUSTOM_OVERRIDE_OPTIONS,
} from 'ee/security_orchestration/components/policy_editor/scan_execution/constants';

describe('CodeBlockOverrideSelector', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMount(CodeBlockOverrideSelector, {
      propsData,
    });
  };

  const findListBox = () => wrapper.findComponent(GlCollapsibleListbox);

  it('selects action type', () => {
    createComponent();
    expect(findListBox().props('selected')).toBe('inject');
    findListBox().vm.$emit('select', INJECT);
    expect(wrapper.emitted('select')).toEqual([[INJECT]]);
    findListBox().vm.$emit('select', OVERRIDE);
    expect(wrapper.emitted('select')[1]).toEqual([OVERRIDE]);
  });

  it.each([INJECT, OVERRIDE])('renders override type', (overrideType) => {
    createComponent({
      propsData: {
        overrideType,
      },
    });

    expect(findListBox().props('selected')).toBe(overrideType);
    expect(findListBox().props('toggleText')).toBe(CUSTOM_OVERRIDE_OPTIONS[overrideType]);
  });
});

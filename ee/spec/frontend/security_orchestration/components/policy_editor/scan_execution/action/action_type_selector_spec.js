import { shallowMount } from '@vue/test-utils';
import { GlCollapsibleListbox } from '@gitlab/ui';
import CodeBlockSourceSelector from 'ee/security_orchestration/components/policy_editor/scan_execution/action/code_block_source_selector.vue';
import {
  INSERTED_CODE_BLOCK,
  LINKED_EXISTING_FILE,
  CUSTOM_ACTION_OPTIONS,
} from 'ee/security_orchestration/components/policy_editor/scan_execution/constants';

describe('ActionTypeSelector', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMount(CodeBlockSourceSelector, {
      propsData,
    });
  };

  const findListBox = () => wrapper.findComponent(GlCollapsibleListbox);

  it('selects action type', () => {
    createComponent();

    expect(findListBox().props('selected')).toBe('');

    findListBox().vm.$emit('select', LINKED_EXISTING_FILE);

    expect(wrapper.emitted('select')).toEqual([[LINKED_EXISTING_FILE]]);

    findListBox().vm.$emit('select', INSERTED_CODE_BLOCK);

    expect(wrapper.emitted('select')[1]).toEqual([INSERTED_CODE_BLOCK]);
  });

  it.each([LINKED_EXISTING_FILE, INSERTED_CODE_BLOCK])('renders selected type', (selectedType) => {
    createComponent({
      propsData: {
        selectedType,
      },
    });

    expect(findListBox().props('selected')).toBe(selectedType);
    expect(findListBox().props('toggleText')).toBe(CUSTOM_ACTION_OPTIONS[selectedType]);
  });
});

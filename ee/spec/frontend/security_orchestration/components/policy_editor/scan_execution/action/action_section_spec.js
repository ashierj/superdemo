import { shallowMount } from '@vue/test-utils';
import ActionSection from 'ee/security_orchestration/components/policy_editor/scan_execution/action/action_section.vue';
import ScanAction from 'ee/security_orchestration/components/policy_editor/scan_execution/action/scan_action.vue';
import CodeBlockAction from 'ee/security_orchestration/components/policy_editor/scan_execution/action/code_block_action.vue';

describe('ActionBuilder', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(ActionSection, {
      propsData: {
        initAction: {
          scan: 'secret_detection',
        },
        ...props,
      },
    });
  };

  const findScanAction = () => wrapper.findComponent(ScanAction);
  const findCodeBlockAction = () => wrapper.findComponent(CodeBlockAction);

  it('should render action section', () => {
    createComponent();

    expect(findScanAction().exists()).toBe(true);
    expect(findCodeBlockAction().exists()).toBe(false);
  });

  it.each(['changed', 'remove', 'parsing-error'])('should emit event', (event) => {
    createComponent();

    findScanAction().vm.$emit(event);
    expect(wrapper.emitted(event)).toHaveLength(1);
  });

  it('should not render custom section for invalid action', () => {
    createComponent({
      props: {
        initAction: {
          invalid: 'custom',
        },
      },
    });

    expect(findScanAction().exists()).toBe(true);
    expect(findCodeBlockAction().exists()).toBe(false);
  });

  describe('custom section', () => {
    beforeEach(() => {
      createComponent({
        props: {
          initAction: {
            scan: 'custom',
          },
        },
      });
    });

    it('should render custom section', () => {
      expect(findScanAction().exists()).toBe(false);
      expect(findCodeBlockAction().exists()).toBe(true);
    });

    it('should emit remove event', () => {
      findCodeBlockAction().vm.$emit('remove');

      expect(wrapper.emitted('remove')).toHaveLength(1);
    });
  });
});

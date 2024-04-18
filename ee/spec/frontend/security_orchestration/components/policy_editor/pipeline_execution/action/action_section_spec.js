import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ActionSection from 'ee/security_orchestration/components/policy_editor/pipeline_execution/action/action_section.vue';
import CodeBlockFilePath from 'ee/security_orchestration/components/policy_editor/scan_execution/action/code_block_file_path.vue';

describe('ActionSection', () => {
  let wrapper;

  const factory = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(ActionSection, {
      propsData: {
        ...propsData,
      },
      provide: {
        ...provide,
      },
    });
  };

  const findCodeBlockFilePath = () => wrapper.findComponent(CodeBlockFilePath);

  it('renders', () => {
    factory();
    expect(findCodeBlockFilePath().exists()).toBe(true);
  });
});

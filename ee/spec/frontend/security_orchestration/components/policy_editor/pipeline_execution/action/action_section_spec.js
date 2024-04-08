import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ActionSection from 'ee/security_orchestration/components/policy_editor/pipeline_execution/action/action_section.vue';

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

  it('renders', () => {
    factory();
    expect(wrapper.find('div').exists()).toBe(true);
  });
});

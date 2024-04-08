import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RuleSection from 'ee/security_orchestration/components/policy_editor/pipeline_execution/rule/rule_section.vue';

describe('RuleSection', () => {
  let wrapper;

  const factory = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(RuleSection, {
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

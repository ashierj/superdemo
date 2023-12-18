import { GlEmptyState } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import App from 'ee/security_orchestration/components/policy_editor/app.vue';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from 'ee/security_orchestration/constants';
import ScanAction from 'ee/security_orchestration/components/policy_editor/scan_execution/action/scan_action.vue';
import RuleSection from 'ee/security_orchestration/components/policy_editor/scan_execution/rule/rule_section.vue';
import { DEFAULT_PROVIDE } from '../mocks';

describe('Policy Editor', () => {
  let wrapper;

  const createWrapper = ({ propsData = {}, provide = {}, glFeatures = {} } = {}) => {
    wrapper = mountExtended(App, {
      propsData: {
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        ...propsData,
      },
      provide: {
        ...DEFAULT_PROVIDE,
        glFeatures,
        ...provide,
      },
    });
  };

  const findSelectScanExecutionPolicyButton = () =>
    wrapper.findByTestId('select-policy-scan_execution_policy');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findScanAction = () => wrapper.findComponent(ScanAction);
  const findRuleSection = () => wrapper.findComponent(RuleSection);

  beforeEach(() => {
    createWrapper();
    findSelectScanExecutionPolicyButton().vm.$emit('click');
  });

  afterEach(() => {
    window.gon = {};
  });

  describe('rendering', () => {
    it('renders the page correctly', () => {
      expect(findEmptyState().exists()).toBe(false);
      expect(findScanAction().exists()).toBe(true);
      expect(findRuleSection().exists()).toBe(true);
    });
  });
});

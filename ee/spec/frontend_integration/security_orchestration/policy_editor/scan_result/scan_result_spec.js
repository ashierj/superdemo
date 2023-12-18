import { GlEmptyState } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import App from 'ee/security_orchestration/components/policy_editor/app.vue';
import SettingsSection from 'ee/security_orchestration/components/policy_editor/scan_result/settings/settings_section.vue';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from 'ee/security_orchestration/constants';
import ActionSection from 'ee/security_orchestration/components/policy_editor/scan_result/action/action_section.vue';
import RuleSection from 'ee/security_orchestration/components/policy_editor/scan_result/rule/rule_section.vue';
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

  const findSelectScanResultPolicyButton = () =>
    wrapper.findByTestId('select-policy-scan_result_policy');
  const findYamlPreview = () => wrapper.findByTestId('rule-editor-preview');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findActionSection = () => wrapper.findComponent(ActionSection);
  const findRuleSection = () => wrapper.findComponent(RuleSection);
  const findSettingsSection = () => wrapper.findComponent(SettingsSection);

  beforeEach(() => {
    createWrapper();
    findSelectScanResultPolicyButton().vm.$emit('click');
  });

  afterEach(() => {
    window.gon = {};
  });

  describe('rendering', () => {
    it('renders the page correctly', () => {
      expect(findEmptyState().exists()).toBe(false);
      expect(findActionSection().exists()).toBe(true);
      expect(findRuleSection().exists()).toBe(true);
      expect(findSettingsSection().exists()).toBe(false);
      expect(findYamlPreview().exists()).toBe(true);
    });
  });
});

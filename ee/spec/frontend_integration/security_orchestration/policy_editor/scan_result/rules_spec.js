import { mountExtended } from 'helpers/vue_test_utils_helper';
import App from 'ee/security_orchestration/components/policy_editor/app.vue';
import DefaultRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result/rule/default_rule_builder.vue';
import ScanTypeSelect from 'ee/security_orchestration/components/policy_editor/scan_result/rule/scan_type_select.vue';
import AnyMergeRequestRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result/rule/any_merge_request_rule_builder.vue';
import LicenseScanRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result/rule/license_scan_rule_builder.vue';
import SecurityScanRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result/rule/security_scan_rule_builder.vue';
import SettingsItem from 'ee/security_orchestration/components/policy_editor/scan_result/settings/settings_item.vue';
import SettingsSection from 'ee/security_orchestration/components/policy_editor/scan_result/settings/settings_section.vue';
import RuleSection from 'ee/security_orchestration/components/policy_editor/scan_result/rule/rule_section.vue';
import YamlEditor from 'ee/security_orchestration/components/yaml_editor.vue';
import SegmentedControlButtonGroup from '~/vue_shared/components/segmented_control_button_group.vue';
import * as urlUtils from '~/lib/utils/url_utility';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from 'ee/security_orchestration/constants';
import {
  ANY_MERGE_REQUEST,
  SCAN_FINDING,
  LICENSE_FINDING,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib';
import {
  EDITOR_MODE_RULE,
  EDITOR_MODE_YAML,
} from 'ee/security_orchestration/components/policy_editor/constants';
import waitForPromises from 'helpers/wait_for_promises';
import {
  DEFAULT_PROVIDE,
  mockSecurityScanResultManifest,
  mockLicenseScanResultManifest,
  mockAnyMergeRequestScanResultManifest,
} from '../mocks';

describe('Scan result policy rules', () => {
  let wrapper;

  const createWrapper = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = mountExtended(App, {
      propsData: {
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        ...propsData,
      },
      provide: {
        ...DEFAULT_PROVIDE,
        ...provide,
        scanResultPolicyApprovers: {},
      },
      stubs: {
        SourceEditor: true,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(urlUtils, 'getParameterByName').mockReturnValue('scan_result_policy');
  });

  afterEach(() => {
    window.gon = {};
  });

  const findYamlPreview = () => wrapper.findByTestId('rule-editor-preview-content');
  const findYamlEditor = () => wrapper.findComponent(YamlEditor);
  const findSecurityScanRuleBuilder = () => wrapper.findComponent(SecurityScanRuleBuilder);
  const findLicenseScanRuleBuilder = () => wrapper.findComponent(LicenseScanRuleBuilder);
  const findDefaultRuleBuilder = () => wrapper.findComponent(DefaultRuleBuilder);
  const findScanTypeSelect = () => wrapper.findComponent(ScanTypeSelect);
  const findAnyMergeRequestRuleBuilder = () => wrapper.findComponent(AnyMergeRequestRuleBuilder);
  const findRuleSection = () => wrapper.findComponent(RuleSection);
  const findSegmentedControlButtonGroup = () => wrapper.findComponent(SegmentedControlButtonGroup);
  const findSettingsSection = () => wrapper.findComponent(SettingsSection);
  const findAllSettingsItem = () => wrapper.findAllComponents(SettingsItem);

  const switchRuleMode = async (mode, awaitPromise = true) => {
    await findSegmentedControlButtonGroup().vm.$emit('input', mode);

    if (awaitPromise) {
      await waitForPromises();
    }
  };

  const normaliseYaml = (yaml) => yaml.replaceAll('\n', '');
  const getYamlPreviewText = () => findYamlPreview().text();

  const verify = async ({ manifest, verifyRuleMode }) => {
    verifyRuleMode();
    expect(normaliseYaml(getYamlPreviewText())).toBe(normaliseYaml(manifest));
    await switchRuleMode(EDITOR_MODE_YAML);
    expect(findYamlEditor().props('value')).toBe(manifest);
    await switchRuleMode(EDITOR_MODE_RULE, false);

    expect(normaliseYaml(getYamlPreviewText())).toBe(normaliseYaml(manifest));
    verifyRuleMode();
  };

  describe('initial state', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render rule section', () => {
      expect(findRuleSection().exists()).toBe(true);
      expect(findDefaultRuleBuilder().exists()).toBe(true);
      expect(findYamlPreview().text()).toContain("rules:\n  - type: ''");
    });
  });

  describe('security scan', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should select security scan rule', async () => {
      const verifyRuleMode = () => {
        expect(findDefaultRuleBuilder().exists()).toBe(false);
        expect(findSecurityScanRuleBuilder().exists()).toBe(true);
        expect(findSettingsSection().exists()).toBe(false);
      };

      await findScanTypeSelect().vm.$emit('select', SCAN_FINDING);
      await verify({
        manifest: mockSecurityScanResultManifest,
        verifyRuleMode,
      });
    });
  });

  describe('license rule', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should select licence rule', async () => {
      const verifyRuleMode = () => {
        expect(findDefaultRuleBuilder().exists()).toBe(false);
        expect(findLicenseScanRuleBuilder().exists()).toBe(true);
        expect(findSettingsSection().exists()).toBe(false);
      };
      await findScanTypeSelect().vm.$emit('select', LICENSE_FINDING);
      await verify({ manifest: mockLicenseScanResultManifest, verifyRuleMode });
    });
  });

  describe('any merge request rule', () => {
    beforeEach(() => {
      createWrapper({
        provide: { glFeatures: { scanResultAnyMergeRequest: true } },
      });
    });

    it('should select any merge request rule', async () => {
      const verifyRuleMode = () => {
        expect(findDefaultRuleBuilder().exists()).toBe(false);
        expect(findAnyMergeRequestRuleBuilder().exists()).toBe(true);
        expect(findSettingsSection().exists()).toBe(true);
        expect(findAllSettingsItem()).toHaveLength(1);
      };

      await findScanTypeSelect().vm.$emit('select', ANY_MERGE_REQUEST);
      await verify({ manifest: mockAnyMergeRequestScanResultManifest, verifyRuleMode });
    });
  });
});

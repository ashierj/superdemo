import { mountExtended } from 'helpers/vue_test_utils_helper';
import * as urlUtils from '~/lib/utils/url_utility';
import App from 'ee/security_orchestration/components/policy_editor/app.vue';
import GroupDastProfileSelector from 'ee/security_orchestration/components/policy_editor/scan_execution/action/scan_filters/group_dast_profile_selector.vue';
import ProjectDastProfileSelector from 'ee/security_orchestration/components/policy_editor/scan_execution/action/scan_filters/project_dast_profile_selector.vue';
import RunnerTagsList from 'ee/security_orchestration/components/policy_editor/scan_execution/action/scan_filters/runner_tags_list.vue';
import ScanFilterSelector from 'ee/security_orchestration/components/policy_editor/scan_filter_selector.vue';
import ScanAction from 'ee/security_orchestration/components/policy_editor/scan_execution/action/scan_action.vue';
import {
  DEFAULT_ASSIGNED_POLICY_PROJECT,
  NAMESPACE_TYPES,
} from 'ee/security_orchestration/constants';
import { CI_VARIABLE } from 'ee/security_orchestration/components/policy_editor/scan_execution/action/scan_filters/constants';
import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_SAST_IAC,
  REPORT_TYPE_DAST,
  REPORT_TYPE_SECRET_DETECTION,
  REPORT_TYPE_DEPENDENCY_SCANNING,
  REPORT_TYPE_CONTAINER_SCANNING,
} from '~/vue_shared/security_reports/constants';
import { DEFAULT_PROVIDE } from '../mocks/mocks';
import {
  createScanActionScanExecutionManifest,
  mockDastActionScanExecutionManifest,
  mockActionsVariablesScanExecutionManifest,
} from '../mocks/action_mocks';
import { verify, findYamlPreview } from '../utils';

describe('Scan execution policy actions', () => {
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
      },
      stubs: {
        SourceEditor: true,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(urlUtils, 'getParameterByName').mockReturnValue('scan_execution_policy');
  });

  afterEach(() => {
    window.gon = {};
  });

  const findScanTypeSelector = () => wrapper.findByTestId('scan-type-selector');
  const findGroupDastProfileSelector = () => wrapper.findComponent(GroupDastProfileSelector);
  const findProjectDastProfileSelector = () => wrapper.findComponent(ProjectDastProfileSelector);
  const findScanAction = () => wrapper.findComponent(ScanAction);
  const findRunnerTagsList = () => wrapper.findComponent(RunnerTagsList);
  const findScanFilterSelector = () => wrapper.findComponent(ScanFilterSelector);

  describe('initial state', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render action section', () => {
      expect(findScanAction().exists()).toBe(true);
      expect(findYamlPreview(wrapper).text()).toContain('actions:\n  - scan: secret_detection');
    });
  });

  describe('secret detection', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('selects secret detection scan as action', async () => {
      const verifyRuleMode = () => {
        expect(findScanAction().exists()).toBe(true);
        expect(findRunnerTagsList().exists()).toBe(true);
        expect(findScanAction().props('initAction')).toEqual({
          scan: REPORT_TYPE_SECRET_DETECTION,
        });
      };

      await verify({
        manifest: createScanActionScanExecutionManifest(REPORT_TYPE_SECRET_DETECTION),
        verifyRuleMode,
        wrapper,
      });
    });
  });

  describe('non dast scanners', () => {
    beforeEach(() => {
      createWrapper();
    });

    it.each`
      scanType
      ${REPORT_TYPE_SAST}
      ${REPORT_TYPE_SAST_IAC}
      ${REPORT_TYPE_CONTAINER_SCANNING}
      ${REPORT_TYPE_DEPENDENCY_SCANNING}
    `(`selects secret detection $scanType as action`, async ({ scanType }) => {
      const verifyRuleMode = () => {
        expect(findScanAction().exists()).toBe(true);
        expect(findRunnerTagsList().exists()).toBe(true);
        expect(findScanAction().props('initAction')).toEqual({ scan: scanType });
      };

      await findScanTypeSelector().vm.$emit('select', scanType);

      await verify({
        manifest: createScanActionScanExecutionManifest(scanType),
        verifyRuleMode,
        wrapper,
      });
    });
  });

  describe('dast scanner', () => {
    it.each`
      namespaceType              | findDastSelector
      ${NAMESPACE_TYPES.PROJECT} | ${findProjectDastProfileSelector}
      ${NAMESPACE_TYPES.GROUP}   | ${findGroupDastProfileSelector}
    `('selects secret detection dast as action', async ({ namespaceType, findDastSelector }) => {
      createWrapper({
        provide: {
          namespaceType,
        },
      });

      const verifyRuleMode = () => {
        expect(findScanAction().exists()).toBe(true);
        expect(findDastSelector().exists()).toBe(true);
        expect(findRunnerTagsList().exists()).toBe(true);
        expect(findScanAction().props('initAction')).toEqual({
          scan: REPORT_TYPE_DAST,
          site_profile: '',
          scanner_profile: '',
        });
      };

      await findScanTypeSelector().vm.$emit('select', REPORT_TYPE_DAST);

      await verify({ manifest: mockDastActionScanExecutionManifest, verifyRuleMode, wrapper });
    });
  });

  describe('actions filters', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('selects variables filter', async () => {
      const verifyRuleMode = () => {
        expect(findScanAction().props('initAction')).toEqual({
          scan: REPORT_TYPE_SECRET_DETECTION,
          variables: { '': '' },
        });
      };

      await findScanFilterSelector().vm.$emit('select', CI_VARIABLE);
      await verify({
        manifest: mockActionsVariablesScanExecutionManifest,
        verifyRuleMode,
        wrapper,
      });
    });
  });
});

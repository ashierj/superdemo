import { convertToTitleCase } from '~/lib/utils/text_utility';
import DetailsDrawer from 'ee/security_orchestration/components/policy_drawer/scan_result/details_drawer.vue';
import ToggleList from 'ee/security_orchestration/components/policy_drawer/toggle_list.vue';
import PolicyDrawerLayout from 'ee/security_orchestration/components/policy_drawer/drawer_layout.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import Approvals from 'ee/security_orchestration/components/policy_drawer/scan_result/policy_approvals.vue';
import Settings from 'ee/security_orchestration/components/policy_drawer/scan_result/policy_settings.vue';
import {
  mockProjectScanResultPolicy,
  mockProjectWithAllApproverTypesScanResultPolicy,
  mockApprovalSettingsScanResultPolicy,
} from '../../../mocks/mock_scan_result_policy_data';

describe('DetailsDrawer component', () => {
  let wrapper;

  const findSummary = () => wrapper.findByTestId('policy-summary');
  const findPolicyApprovals = () => wrapper.findComponent(Approvals);
  const findPolicyDrawerLayout = () => wrapper.findComponent(PolicyDrawerLayout);
  const findToggleList = () => wrapper.findComponent(ToggleList);
  const findSettings = () => wrapper.findComponent(Settings);

  const factory = ({ propsData } = {}) => {
    wrapper = shallowMountExtended(DetailsDrawer, {
      propsData,
      provide: { namespaceType: NAMESPACE_TYPES.PROJECT },
      stubs: {
        PolicyDrawerLayout,
      },
    });
  };

  describe('policy drawer layout props', () => {
    it('passes the policy to the PolicyDrawerLayout component', () => {
      factory({ propsData: { policy: mockProjectScanResultPolicy } });
      expect(findPolicyDrawerLayout().props('policy')).toBe(mockProjectScanResultPolicy);
    });

    it('passes the description to the PolicyDrawerLayout component', () => {
      factory({ propsData: { policy: mockProjectScanResultPolicy } });
      expect(findPolicyDrawerLayout().props('description')).toBe(
        'This policy enforces critical vulnerability CS approvals',
      );
    });
  });

  describe('summary', () => {
    it('renders the policy summary', () => {
      factory({ propsData: { policy: mockProjectScanResultPolicy } });
      expect(findSummary().exists()).toBe(true);
    });

    describe('settings', () => {
      it('passes the settings to the "Settings" component if settings are present', () => {
        factory({ propsData: { policy: mockApprovalSettingsScanResultPolicy } });
        expect(findSettings().props('settings')).toEqual(
          mockApprovalSettingsScanResultPolicy.approval_settings,
        );
      });

      it('passes the empty object to the "Settings" component if no settings are present', () => {
        factory({ propsData: { policy: mockProjectScanResultPolicy } });
        expect(findSettings().props('settings')).toEqual({});
      });
    });

    describe('approvals', () => {
      it('renders the "Approvals" component correctly', () => {
        factory({ propsData: { policy: mockProjectWithAllApproverTypesScanResultPolicy } });
        expect(findPolicyApprovals().exists()).toBe(true);
        expect(findPolicyApprovals().props('approvers')).toStrictEqual([
          ...mockProjectWithAllApproverTypesScanResultPolicy.allGroupApprovers,
          ...mockProjectWithAllApproverTypesScanResultPolicy.roleApprovers.map((r) =>
            convertToTitleCase(r.toLowerCase()),
          ),
          ...mockProjectWithAllApproverTypesScanResultPolicy.userApprovers,
        ]);
      });

      it('should not render branch exceptions list without exceptions', () => {
        factory({ propsData: { policy: mockProjectWithAllApproverTypesScanResultPolicy } });
        expect(findToggleList().exists()).toBe(false);
      });
    });
  });
});

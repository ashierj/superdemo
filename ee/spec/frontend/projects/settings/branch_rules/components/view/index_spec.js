import Vue from 'vue';
import VueApollo from 'vue-apollo';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import RuleView from 'ee/projects/settings/branch_rules/components/view/index.vue';
import ApprovalRulesApp from 'ee/approvals/components/approval_rules_app.vue';
import ProjectRules from 'ee/approvals/project_settings/project_rules.vue';
import branchRulesQuery from 'ee/projects/settings/branch_rules/queries/branch_rules_details.query.graphql';
import { createStoreOptions } from 'ee/approvals/stores';
import projectSettingsModule from 'ee/approvals/stores/modules/project_settings';
import deleteBranchRuleMutation from '~/projects/settings/branch_rules/mutations/branch_rule_delete.mutation.graphql';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  I18N,
  REQUIRED_ICON,
  NOT_REQUIRED_ICON,
  REQUIRED_ICON_CLASS,
  NOT_REQUIRED_ICON_CLASS,
} from '~/projects/settings/branch_rules/components/view/constants';
import Protection from '~/projects/settings/branch_rules/components/view/protection.vue';
import { sprintf } from '~/locale';
import {
  deleteBranchRuleMockResponse,
  branchProtectionsMockResponse,
  statusChecksRulesMock,
} from './mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterByName: jest.fn().mockReturnValue('main'),
  mergeUrlParams: jest.fn().mockReturnValue('/branches?state=all&search=main'),
  joinPaths: jest.fn(),
}));

Vue.use(VueApollo);
Vue.use(Vuex);

const protectionMockProps = {
  headerLinkHref: 'protected/branches',
  headerLinkTitle: I18N.manageProtectionsLinkTitle,
  roles: [{ accessLevelDescription: 'Maintainers' }],
  users: [{ avatarUrl: 'test.com/user.png', name: 'peter', webUrl: 'test.com' }],
};

describe('View branch rules in enterprise edition', () => {
  let wrapper;
  let fakeApollo;
  let store;
  let axiosMock;
  const projectPath = 'test/testing';
  const protectedBranchesPath = 'protected/branches';
  const approvalRulesPath = 'approval/rules';
  const statusChecksPath = 'status/checks';
  const branchProtectionsMockRequestHandler = (response = branchProtectionsMockResponse) =>
    jest.fn().mockResolvedValue(response);
  const deleteBranchRuleMockRequestHandler = (response = deleteBranchRuleMockResponse) =>
    jest.fn().mockResolvedValue(response);

  const createComponent = async (
    { showApprovers, showStatusChecks, showCodeOwners } = {},
    mockResponse,
    mutationMockResponse,
  ) => {
    axiosMock = new MockAdapter(axios);
    store = createStoreOptions({ approvals: projectSettingsModule() });
    jest.spyOn(store.modules.approvals.actions, 'setRulesFilter');
    jest.spyOn(store.modules.approvals.actions, 'fetchRules');

    fakeApollo = createMockApollo([
      [branchRulesQuery, branchProtectionsMockRequestHandler(mockResponse)],
      [deleteBranchRuleMutation, deleteBranchRuleMockRequestHandler(mutationMockResponse)],
    ]);

    wrapper = shallowMountExtended(RuleView, {
      store: new Vuex.Store(store),
      apolloProvider: fakeApollo,
      provide: {
        projectPath,
        protectedBranchesPath,
        approvalRulesPath,
        statusChecksPath,
        showApprovers,
        showStatusChecks,
        showCodeOwners,
      },
    });

    await waitForPromises();
  };

  beforeEach(() => createComponent());

  afterEach(() => axiosMock.restore());

  const findBranchProtections = () => wrapper.findAllComponents(Protection);
  const findApprovalsApp = () => wrapper.findComponent(ApprovalRulesApp);
  const findProjectRules = () => wrapper.findComponent(ProjectRules);
  const findStatusChecksTitle = () => wrapper.findByText(I18N.statusChecksTitle);
  const findCodeOwnerApprovalIcon = () => wrapper.findByTestId('code-owners-icon');
  const findCodeOwnerApprovalTitle = (title) => wrapper.findByText(title);
  const findCodeOwnerApprovalDescription = (description) => wrapper.findByText(description);

  it('renders a branch protection component for push rules', () => {
    expect(findBranchProtections().at(0).props()).toMatchObject({
      header: sprintf(I18N.allowedToPushHeader, { total: 2 }),
      ...protectionMockProps,
    });
  });

  it('renders a branch protection component for merge rules', () => {
    expect(findBranchProtections().at(1).props()).toMatchObject({
      header: sprintf(I18N.allowedToMergeHeader, { total: 2 }),
      ...protectionMockProps,
    });
  });

  describe('Code owner approvals', () => {
    it('does not render a code owner approval section by default', () => {
      expect(findCodeOwnerApprovalIcon().exists()).toBe(false);
      expect(findCodeOwnerApprovalTitle(I18N.requiresCodeOwnerApprovalTitle).exists()).toBe(false);
      expect(
        findCodeOwnerApprovalDescription(I18N.requiresCodeOwnerApprovalDescription).exists(),
      ).toBe(false);
    });

    it.each`
      codeOwnerApprovalRequired | iconName             | iconClass                  | title                                        | description
      ${true}                   | ${REQUIRED_ICON}     | ${REQUIRED_ICON_CLASS}     | ${I18N.requiresCodeOwnerApprovalTitle}       | ${I18N.requiresCodeOwnerApprovalDescription}
      ${false}                  | ${NOT_REQUIRED_ICON} | ${NOT_REQUIRED_ICON_CLASS} | ${I18N.doesNotRequireCodeOwnerApprovalTitle} | ${I18N.doesNotRequireCodeOwnerApprovalDescription}
    `(
      'code owners with the correct icon, title and description',
      async ({ codeOwnerApprovalRequired, iconName, iconClass, title, description }) => {
        const mockResponse = branchProtectionsMockResponse;
        mockResponse.data.project.branchRules.nodes[0].branchProtection.codeOwnerApprovalRequired = codeOwnerApprovalRequired;
        await createComponent({ showCodeOwners: true }, mockResponse);

        expect(findCodeOwnerApprovalIcon().props('name')).toBe(iconName);
        expect(findCodeOwnerApprovalIcon().attributes('class')).toBe(iconClass);
        expect(findCodeOwnerApprovalTitle(title).exists()).toBe(true);
        expect(findCodeOwnerApprovalTitle(description).exists()).toBe(true);
      },
    );
  });

  it('does not render approvals and status checks sections by default', () => {
    expect(findApprovalsApp().exists()).toBe(false);
    expect(findStatusChecksTitle().exists()).toBe(false);
  });

  describe('if "showApprovers" is true', () => {
    beforeEach(() => createComponent({ showApprovers: true }));

    it('sets an approval rules filter', () => {
      expect(store.modules.approvals.actions.setRulesFilter).toHaveBeenCalledWith(
        expect.anything(),
        ['test'],
      );
    });

    it('fetches the approval rules', () => {
      expect(store.modules.approvals.actions.fetchRules).toHaveBeenCalledTimes(1);
    });

    it('re-fetches the approval rules when a rule is successfully added/edited', async () => {
      findApprovalsApp().vm.$emit('submitted');
      await waitForPromises();

      expect(store.modules.approvals.actions.setRulesFilter).toHaveBeenCalledTimes(2);
      expect(store.modules.approvals.actions.fetchRules).toHaveBeenCalledTimes(2);
    });

    it('renders the approval rules component with correct props', () => {
      expect(findApprovalsApp().props('isMrEdit')).toBe(false);
    });

    it('renders the project rules component', () => {
      expect(findProjectRules().exists()).toBe(true);
    });
  });

  it('renders a branch protection component for status checks  if "showStatusChecks" is true', async () => {
    await createComponent({ showStatusChecks: true });

    expect(findStatusChecksTitle().exists()).toBe(true);

    expect(findBranchProtections().at(2).props()).toMatchObject({
      header: sprintf(I18N.statusChecksHeader, { total: statusChecksRulesMock.length }),
      headerLinkHref: statusChecksPath,
      headerLinkTitle: I18N.statusChecksLinkTitle,
      statusChecks: statusChecksRulesMock,
    });
  });
});

import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlFormTextarea, GlAlert, GlButton } from '@gitlab/ui';
import mockDeploymentFixture from 'test_fixtures/ee/graphql/deployments/graphql/queries/deployment.query.graphql.json';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import DeploymentApprovals from 'ee/deployments/components/deployment_approvals.vue';
import approveDeploymentMutation from 'ee/deployments/graphql/mutations/approve_deployment.mutation.graphql';
import MultipleApprovalRulesTable from 'ee/environments/components/multiple_approval_rules_table.vue';

jest.mock('~/sentry/sentry_browser_wrapper');

const { deployment } = mockDeploymentFixture.data.project;

Vue.use(VueApollo);

describe('ee/deployments/components/deployment_approvals.vue', () => {
  let wrapper;
  let mockApprove;

  const createComponent = ({ propsData = {} } = {}) => {
    const apolloProvider = createMockApollo([[approveDeploymentMutation, mockApprove]]);
    wrapper = shallowMountExtended(DeploymentApprovals, {
      apolloProvider,
      propsData: {
        deployment,
        approvalSummary: deployment.approvalSummary,
        ...propsData,
      },
    });
  };

  beforeEach(() => {
    mockApprove = jest.fn();
  });

  const findHeader = () => wrapper.findByTestId('deployment-approval-header');
  const findCommentBox = () => wrapper.findComponent(GlFormTextarea);
  const findButtons = () => wrapper.findAllComponents(GlButton);
  const findApproveButton = () => findButtons().wrappers.at(0);
  const findRejectButton = () => findButtons().wrappers.at(-1);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findCharacterCount = () => wrapper.findByTestId('approval-character-count');

  it('shows a header listing how many approvals remain', () => {
    createComponent();

    expect(findHeader().text()).toContain(
      `Requires ${deployment.approvalSummary.totalPendingApprovalCount} approvals`,
    );
  });

  it('shows the approval table when deployment needs approval', () => {
    createComponent();

    expect(wrapper.findComponent(MultipleApprovalRulesTable).props('rules')).toBe(
      deployment.approvalSummary.rules,
    );
  });

  describe('can approve', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          deployment: {
            ...deployment,
            status: 'BLOCKED',
            userPermissions: { approveDeployment: true },
          },
          approvalSummary: {
            ...deployment.approvalSummary,
            status: 'PENDING_APPROVAL',
            approvals: [],
          },
        },
      });
    });

    it('shows an input box for users to enter a comment', () => {
      expect(findCommentBox().exists()).toBe(true);
    });

    it.each`
      buttonFinder         | otherButton          | status
      ${findApproveButton} | ${findRejectButton}  | ${'APPROVED'}
      ${findRejectButton}  | ${findApproveButton} | ${'REJECTED'}
    `(
      'fires the $status action when appropriate button clicked',
      async ({ buttonFinder, otherButton, status }) => {
        mockApprove.mockReturnValue(new Promise(() => {}));
        const button = buttonFinder();
        button.vm.$emit('click');

        await nextTick();

        expect(button.props('loading')).toBe(true);
        expect(otherButton().props('disabled')).toBe(true);
        expect(otherButton().props('loading')).toBe(false);
        expect(mockApprove).toHaveBeenCalledWith({
          input: {
            comment: '',
            id: deployment.id,
            status,
          },
        });
      },
    );

    it('shows an error message if one is returned', async () => {
      const error = 'ERROR!!!';
      mockApprove.mockResolvedValue({
        data: { approveDeployment: { errors: [error], deploymentApproval: null } },
      });
      const button = findApproveButton();
      await button.vm.$emit('click');
      await waitForPromises();

      expect(findAlert().text()).toBe(error);
    });

    it('sends any other exceptions to sentry', async () => {
      const error = new Error();
      mockApprove.mockRejectedValue(error);
      const button = findApproveButton();
      await button.vm.$emit('click');
      await waitForPromises();

      expect(captureException).toHaveBeenCalledWith(error);
      expect(findAlert().text()).toBe(
        'Something went wrong approving or rejecting the deployment. Please try again later.',
      );
    });

    it('disables the approve and reject buttons if the form is invalid', async () => {
      findCommentBox().vm.$emit('input', new Array(251).fill('a').join(''));
      await nextTick();

      findButtons().wrappers.forEach((button) =>
        expect(button.attributes('disabled')).toBe('true'),
      );
    });

    it.each`
      count  | classes                 | tooltip
      ${50}  | ${'gl-align-self-end'}  | ${'Characters left'}
      ${230} | ${'gl-text-orange-500'} | ${'Characters left'}
      ${251} | ${'gl-text-red-500'}    | ${'Characters over limit'}
    `(
      'shows the remaining characters a user can input for a comment for $count characters',
      async ({ count, classes, tooltip }) => {
        findCommentBox().vm.$emit('input', new Array(count).fill('a').join(''));
        await nextTick();

        const countText = findCharacterCount();
        expect(countText.text()).toBe(`${250 - count}`);
        expect(countText.classes(classes)).toBe(true);
        expect(countText.attributes('title')).toBe(tooltip);
      },
    );
  });

  describe('can not approve', () => {
    it('does not show the approval form', () => {
      createComponent({
        propsData: {
          deployment: {
            ...deployment,
            userPermissions: { approveDeployment: false },
          },
          approvalSummary: {
            ...deployment.approvalSummary,
            approvals: [],
          },
        },
      });

      expect(findCommentBox().exists()).toBe(false);
      expect(findButtons()).toHaveLength(0);
    });
  });
});

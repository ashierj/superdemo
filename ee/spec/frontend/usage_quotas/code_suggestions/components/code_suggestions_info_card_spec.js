import { GlLink, GlSprintf, GlButton, GlSkeletonLoader } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import Tracking from '~/tracking';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';
import CodeSuggestionsInfoCard from 'ee/usage_quotas/code_suggestions/components/code_suggestions_info_card.vue';
import { getSubscriptionPermissionsData } from 'ee/fulfillment/shared_queries/subscription_actions_reason.customer.query.graphql';
import { createMockClient } from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);

const defaultProvide = {
  addDuoProHref: 'http://customers.gitlab.com/namespaces/10/duo_pro_seats',
  isSaaS: true,
};

describe('CodeSuggestionsInfoCard', () => {
  let wrapper;
  const defaultProps = { groupId: '4321' };
  const defaultApolloData = {
    subscription: {
      canAddSeats: false,
      canRenew: false,
      communityPlan: false,
      canAddDuoProSeats: true,
    },
    userActionAccess: { limitedAccessReason: 'INVALID_REASON' },
  };

  const findCodeSuggestionsDescription = () => wrapper.findByTestId('description');
  const findCodeSuggestionsLearnMoreLink = () => wrapper.findComponent(GlLink);
  const findCodeSuggestionsInfoTitle = () => wrapper.findByTestId('title');
  const findAddSeatsButton = () => wrapper.findComponent(GlButton);

  const createComponent = (options = {}) => {
    const { props = {}, provide = {}, apolloData = defaultApolloData } = options;

    const queryHandlerMock = jest.fn().mockResolvedValue({
      data: apolloData,
    });
    const mockCustomersDotClient = createMockClient([
      [getSubscriptionPermissionsData, queryHandlerMock],
    ]);
    const mockGitlabClient = createMockClient();
    const mockApollo = new VueApollo({
      defaultClient: mockGitlabClient,
      clients: { customersDotClient: mockCustomersDotClient, gitlabClient: mockGitlabClient },
    });

    wrapper = shallowMountExtended(CodeSuggestionsInfoCard, {
      propsData: { ...defaultProps, ...props },
      provide: { ...defaultProvide, ...provide },
      apolloProvider: mockApollo,
      stubs: {
        GlSprintf,
        UsageStatistics: {
          template: `
            <div>
                <slot name="actions"></slot>
                <slot name="description"></slot>
                <slot name="additional-info"></slot>
            </div>
            `,
        },
      },
    });
  };

  describe('when `isLoading` computed value is `true`', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders `GlSkeletonLoader`', () => {
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });
  });

  describe('general rendering', () => {
    beforeEach(async () => {
      createComponent();

      // wait for apollo to load
      await waitForPromises();
    });

    it('renders the component', () => {
      expect(wrapper.exists()).toBe(true);
    });

    it('renders the description text', () => {
      expect(findCodeSuggestionsDescription().text()).toBe(
        "Code Suggestions uses generative AI to suggest code while you're developing.",
      );
    });

    it('renders the learn more link', () => {
      expect(findCodeSuggestionsLearnMoreLink().attributes('href')).toBe(
        `${PROMO_URL}/solutions/code-suggestions/`,
      );
    });

    it('renders the title text', () => {
      expect(findCodeSuggestionsInfoTitle().text()).toBe('GitLab Duo Pro add-on');
    });
  });

  describe('add seats button', () => {
    describe('when link is present', () => {
      beforeEach(async () => {
        createComponent();

        // wait for apollo to load
        await waitForPromises();
      });

      it('renders button if addDuoProHref link is passed', () => {
        expect(findAddSeatsButton().exists()).toBe(true);
      });

      it('renders button with the correct attributes', () => {
        expect(findAddSeatsButton().attributes()).toMatchObject({
          href: defaultProvide.addDuoProHref,
          target: '_blank',
        });
      });
    });

    it('does not render add seats button if link is empty', async () => {
      createComponent({ provide: { addDuoProHref: '' } });
      // wait for apollo to load
      await waitForPromises();
      expect(findAddSeatsButton().exists()).toBe(false);
    });

    it('does not render add seats button if canAddDuoProSeats is false', async () => {
      createComponent({
        apolloData: {
          subscription: {
            canAddSeats: false,
            canRenew: false,
            communityPlan: false,
            canAddDuoProSeats: false,
          },
          userActionAccess: { limitedAccessReason: 'INVALID_REASON' },
        },
      });

      // wait for apollo to load
      await waitForPromises();

      expect(findAddSeatsButton().exists()).toBe(false);
    });

    it('does not render add seats button if  groupId is null', async () => {
      createComponent({ props: { groupId: null } });

      // wait for apollo to load
      await waitForPromises();

      expect(findAddSeatsButton().exists()).toBe(false);
    });

    describe('tracking', () => {
      beforeEach(() => {
        jest.spyOn(Tracking, 'event');
      });

      it.each`
        isSaaS   | label
        ${true}  | ${'add_duo_pro_saas'}
        ${false} | ${'add_duo_pro_sm'}
      `('tracks the click with correct labels', async ({ isSaaS, label }) => {
        createComponent({ provide: { isSaaS } });
        await waitForPromises();
        findAddSeatsButton().vm.$emit('click');
        expect(Tracking.event).toHaveBeenCalledWith(
          undefined,
          'click_button',
          expect.objectContaining({
            property: 'usage_quotas_page',
            label,
          }),
        );
      });
    });
  });
});

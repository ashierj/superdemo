import { GlLink, GlSprintf, GlButton, GlSkeletonLoader } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import Tracking from '~/tracking';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { PROMO_URL, visitUrl } from 'jh_else_ce/lib/utils/url_utility';
import CodeSuggestionsInfoCard from 'ee/usage_quotas/code_suggestions/components/code_suggestions_info_card.vue';
import { getSubscriptionPermissionsData } from 'ee/fulfillment/shared_queries/subscription_actions_reason.customer.query.graphql';
import { createMockClient } from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import LimitedAccessModal from 'ee/usage_quotas/components/limited_access_modal.vue';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

const defaultProvide = {
  addDuoProHref: 'http://customers.gitlab.com/namespaces/10/duo_pro_seats',
  isSaaS: true,
  subscriptionName: null,
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
  const findLimitedAccessModal = () => wrapper.findComponent(LimitedAccessModal);

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
        LimitedAccessModal,
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
    describe('with self-managed', () => {
      it('renders button if addDuoProHref link is passed', async () => {
        createComponent({ provide: { isSaas: false } });
        // wait for apollo to load
        await waitForPromises();
        expect(findAddSeatsButton().exists()).toBe(true);
      });
    });

    describe('with saas', () => {
      describe('when link is present', () => {
        beforeEach(async () => {
          createComponent();

          // wait for apollo to load
          await waitForPromises();
        });

        it('renders button if addDuoProHref link is passed', () => {
          expect(findAddSeatsButton().exists()).toBe(true);
        });
      });
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

    describe('limited access modal', () => {
      describe.each`
        canAddDuoProSeats | limitedAccessReason
        ${false}          | ${'MANAGED_BY_RESELLER'}
        ${false}          | ${'RAMP_SUBSCRIPTION'}
      `(
        'when canAddDuoProSeats=$canAddDuoProSeats and limitedAccessReason=$limitedAccessReason',
        ({ canAddDuoProSeats, limitedAccessReason }) => {
          beforeEach(async () => {
            createComponent({
              apolloData: {
                subscription: {
                  canAddSeats: false,
                  canRenew: false,
                  communityPlan: false,
                  canAddDuoProSeats,
                },
                userActionAccess: { limitedAccessReason },
              },
            });
            await waitForPromises();

            findAddSeatsButton().vm.$emit('click');

            await nextTick();
          });

          it('shows modal', () => {
            expect(findLimitedAccessModal().isVisible()).toBe(true);
          });

          it('sends correct props', () => {
            expect(findLimitedAccessModal().props('limitedAccessReason')).toBe(limitedAccessReason);
          });

          it('does not navigate to URL', () => {
            expect(visitUrl).not.toHaveBeenCalled();
          });
        },
      );

      describe.each`
        canAddDuoProSeats | limitedAccessReason
        ${true}           | ${'MANAGED_BY_RESELLER'}
        ${true}           | ${'RAMP_SUBSCRIPTION'}
      `(
        'when canAddDuoProSeats=$canAddDuoProSeats and limitedAccessReason=$limitedAccessReason',
        ({ canAddDuoProSeats, limitedAccessReason }) => {
          beforeEach(async () => {
            createComponent({
              apolloData: {
                subscription: {
                  canAddSeats: false,
                  canRenew: false,
                  communityPlan: false,
                  canAddDuoProSeats,
                },
                userActionAccess: { limitedAccessReason },
              },
            });
            await waitForPromises();

            findAddSeatsButton().vm.$emit('click');
            await nextTick();
          });

          it('does not show modal', () => {
            expect(findLimitedAccessModal().exists()).toBe(false);
          });

          it('navigates to URL', () => {
            expect(visitUrl).toHaveBeenCalledWith(defaultProvide.addDuoProHref);
          });
        },
      );
    });
  });
});

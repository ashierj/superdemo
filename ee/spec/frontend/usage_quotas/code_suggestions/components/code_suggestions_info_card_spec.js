import { GlButton, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';
import CodeSuggestionsInfoCard from 'ee/usage_quotas/code_suggestions/components/code_suggestions_info_card.vue';
import Tracking from '~/tracking';

const defaultProvide = {
  addDuoProHref: 'http://customers.gitlab.com/namespaces/10/duo_pro_seats',
  isSaaS: true,
};

describe('CodeSuggestionsInfoCard', () => {
  let wrapper;

  const findCodeSuggestionsDescription = () => wrapper.findByTestId('description');
  const findCodeSuggestionsLearnMoreLink = () => wrapper.findComponent(GlLink);
  const findCodeSuggestionsInfoTitle = () => wrapper.findByTestId('title');
  const findAddSeatsButton = () => wrapper.findComponent(GlButton);

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(CodeSuggestionsInfoCard, {
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
      provide: { ...defaultProvide, ...provide },
    });
  };

  describe('general rendering', () => {
    beforeEach(() => {
      return createComponent();
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
      expect(findCodeSuggestionsInfoTitle().text()).toBe('Duo Pro add-on');
    });
  });

  describe('add seats button', () => {
    describe('when link is present', () => {
      beforeEach(() => {
        return createComponent();
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

    it('does not render add seats button if link is empty', () => {
      createComponent({ provide: { addDuoProHref: '' } });
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
      `('tracks the click with correct labels', ({ isSaaS, label }) => {
        createComponent({ provide: { isSaaS } });
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

import { shallowMount } from '@vue/test-utils';
import { GlEmptyState, GlButton } from '@gitlab/ui';
import CodeSuggestionsIntro from 'ee/usage_quotas/code_suggestions/components/code_suggestions_intro.vue';
import { salesLink } from 'ee/usage_quotas/code_suggestions/constants';
import HandRaiseLead from 'ee/hand_raise_leads/hand_raise_lead/components/hand_raise_lead.vue';

const addDuoProHref = 'http://customers.gitlab.com/namespaces/10/duo_pro_seats';

describe('Code Suggestions Intro', () => {
  let wrapper;
  const emptyState = () => wrapper.findComponent(GlEmptyState);
  const handRaiseLeadButton = () => wrapper.findComponent(HandRaiseLead);
  const findButton = (category) =>
    wrapper.findAllComponents(GlButton).filter((button) => button.props('category') === category);

  const createComponent = (provideProps = {}) => {
    wrapper = shallowMount(CodeSuggestionsIntro, {
      mocks: { GlEmptyState },
      provide: {
        ...provideProps,
      },
    });
  };

  describe('when rendering', () => {
    describe('when not showing hand raise lead button', () => {
      beforeEach(() => {
        return createComponent({ addDuoProHref });
      });

      it('renders gl-empty-state component', () => {
        const purchaseButton = findButton('primary').at(0);
        const salesButton = findButton('secondary').at(0);

        expect(purchaseButton.exists()).toBe(true);
        expect(purchaseButton.attributes('variant')).toBe('confirm');
        expect(purchaseButton.attributes('href')).toBe(addDuoProHref);

        expect(salesButton.exists()).toBe(true);
        expect(salesButton.attributes('variant')).toBe('confirm');
        expect(salesButton.attributes('href')).toBe(salesLink);

        expect(emptyState().exists()).toBe(true);
        expect(handRaiseLeadButton().exists()).toBe(false);
      });
    });

    describe('when showing hand raise lead', () => {
      beforeEach(() => {
        return createComponent({ createHandRaiseLeadPath: 'some-path' });
      });

      it('renders gl-empty-state component without default button, but with hand raise lead', () => {
        const defaultButton = wrapper.find(`a[href="${salesLink}"`);
        expect(emptyState().exists()).toBe(true);
        expect(handRaiseLeadButton().exists()).toBe(true);
        expect(defaultButton.exists()).toBe(false);
      });
    });
  });
});

import { GlFormCheckbox, GlSprintf } from '@gitlab/ui';
import PrivacyPolicyAndTermsConfirm from 'ee/subscriptions/shared/components/privacy_and_terms_confirm.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';

describe('PrivacyAndTermsConfirm', () => {
  let wrapper;

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findPrivacyLink = () => wrapper.findByTestId('privacy-link');
  const findTermsLink = () => wrapper.findByTestId('terms-link');

  const createComponent = (value = false) => {
    wrapper = shallowMountExtended(PrivacyPolicyAndTermsConfirm, {
      propsData: { value },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('when rendering', () => {
    it('displays the checkbox as unchecked by default', () => {
      expect(findCheckbox().attributes('checked')).toBeUndefined();
    });

    it('displays the accept policy and terms text', () => {
      expect(findCheckbox().text()).toMatchInterpolatedText(
        'I accept the Privacy Statement and Terms of Service.',
      );
    });

    it('displays the accept policy link', () => {
      expect(findPrivacyLink().attributes('href')).toBe(`${PROMO_URL}/privacy`);
    });

    it('displays the accept terms link', () => {
      expect(findTermsLink().attributes('href')).toBe(`${PROMO_URL}/terms#subscription`);
    });

    describe('with accepted set to `true`', () => {
      it('displays the checkbox as checked', () => {
        createComponent(true);

        expect(findCheckbox().attributes('checked')).toBe('true');
      });
    });
  });

  describe('when clicking on the checkbox', () => {
    it('emits the `change` event with the checkbox value', () => {
      findCheckbox().vm.$emit('input', true);

      expect(wrapper.emitted('input')).toEqual([[true]]);
    });
  });
});

import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';
import PhoneVerification from 'ee/users/identity_verification/components/phone_verification.vue';
import InternationalPhoneInput from 'ee/users/identity_verification/components/international_phone_input.vue';
import VerifyPhoneVerificationCode from 'ee/users/identity_verification/components/verify_phone_verification_code.vue';
import PhoneVerificationArkoseApp from 'ee/arkose_labs/components/phone_verification_arkose_app.vue';

describe('Phone Verification component', () => {
  let wrapper;

  const PHONE_NUMBER = {
    country: 'US',
    internationalDialCode: '1',
    number: '555',
  };

  const MOCK_PUBLIC_KEY = 'arkose-labs-public-api-key';
  const MOCK_DOMAIN = 'client-api.arkoselabs.com';
  const MOCK_ARKOSE_TOKEN = 'verification-token';

  const findInternationalPhoneInput = () => wrapper.findComponent(InternationalPhoneInput);
  const findVerifyCodeInput = () => wrapper.findComponent(VerifyPhoneVerificationCode);
  const findPhoneExemptionLink = () =>
    wrapper.findByText(s__('IdentityVerification|Verify with a credit card instead?'));

  const findPhoneVerificationArkoseApp = () => wrapper.findComponent(PhoneVerificationArkoseApp);

  const createComponent = (provide = {}, props = {}, glFeatures = {}) => {
    wrapper = shallowMountExtended(PhoneVerification, {
      provide: {
        offerPhoneNumberExemption: true,
        arkose: {
          apiKey: MOCK_PUBLIC_KEY,
          domain: MOCK_DOMAIN,
        },
        phoneNumber: {
          challengeUser: false,
        },
        glFeatures,
        ...provide,
      },
      propsData: props,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('When component loads', () => {
    it('should display InternationalPhoneInput component', () => {
      expect(findInternationalPhoneInput().exists()).toBe(true);
    });

    it('should hide VerifyPhoneVerificationCode component', () => {
      expect(findVerifyCodeInput().exists()).toBe(false);
    });
  });

  describe('On next', () => {
    beforeEach(() => {
      findInternationalPhoneInput().vm.$emit('next', PHONE_NUMBER);
      return nextTick();
    });

    it('should hide InternationalPhoneInput component', () => {
      expect(findInternationalPhoneInput().exists()).toBe(false);
    });

    it('should display VerifyPhoneVerificationCode component', () => {
      expect(findVerifyCodeInput().exists()).toBe(true);
      expect(findVerifyCodeInput().props()).toMatchObject({ latestPhoneNumber: PHONE_NUMBER });
    });

    describe('On back', () => {
      beforeEach(() => {
        findVerifyCodeInput().vm.$emit('back');
        return nextTick();
      });

      it('should display InternationalPhoneInput component', () => {
        expect(findInternationalPhoneInput().exists()).toBe(true);
      });

      it('should hide PhoneVerificationCodeInput component', () => {
        expect(findVerifyCodeInput().exists()).toBe(false);
      });
    });
  });

  describe('On verified', () => {
    beforeEach(async () => {
      findInternationalPhoneInput().vm.$emit('next', PHONE_NUMBER);
      await nextTick();

      findVerifyCodeInput().vm.$emit('verified');
      return nextTick();
    });

    it('should emit completed event', () => {
      expect(wrapper.emitted('completed')).toHaveLength(1);
    });
  });

  describe('On skip-verification', () => {
    beforeEach(() => {
      findInternationalPhoneInput().vm.$emit('skip-verification');
      return nextTick();
    });

    it('should emit completed event', () => {
      expect(wrapper.emitted('completed')).toHaveLength(1);
    });
  });

  describe('when phone exemption is not offered', () => {
    beforeEach(() => {
      createComponent({ offerPhoneNumberExemption: false });
    });

    it('does not show a link to request a phone exemption', () => {
      expect(findPhoneExemptionLink().exists()).toBe(false);
    });
  });

  describe('when phone exemption is offered', () => {
    it('shows a link to request a phone exemption', () => {
      expect(findPhoneExemptionLink().exists()).toBe(true);
    });

    it('emits an `exemptionRequested` event when clicking the link', () => {
      findPhoneExemptionLink().vm.$emit('click');

      expect(wrapper.emitted('exemptionRequested')).toHaveLength(1);
    });
  });

  describe('Arkose challenge', () => {
    it('does not show phone verification arkose app by default', () => {
      expect(findPhoneVerificationArkoseApp().exists()).toBe(false);
    });

    it('passes arkoseChallengeShown prop as false', () => {
      expect(findInternationalPhoneInput().props()).toMatchObject({
        arkoseChallengeShown: false,
        arkoseChallengeSolved: false,
        arkoseToken: '',
      });
    });

    describe('when `arkoseLabsPhoneVerificationChallenge` feature flag is enabled', () => {
      describe('when `challengeUser` is true', () => {
        beforeEach(() => {
          createComponent(
            { phoneNumber: { challengeUser: true } },
            {},
            { arkoseLabsPhoneVerificationChallenge: true },
          );
        });

        it('shows phone verification arkose app', () => {
          expect(findPhoneVerificationArkoseApp().exists()).toBe(true);

          expect(findPhoneVerificationArkoseApp().props()).toMatchObject({
            publicKey: MOCK_PUBLIC_KEY,
            domain: MOCK_DOMAIN,
            resetSession: false,
          });
        });

        it('passes correct arkose props to InternationalPhoneInput', () => {
          expect(findInternationalPhoneInput().props()).toMatchObject({
            arkoseChallengeShown: true,
            arkoseChallengeSolved: false,
            arkoseToken: '',
          });
        });

        it('passes the correct arkose props to VerifyPhoneVerificationCode', async () => {
          findInternationalPhoneInput().vm.$emit('next', PHONE_NUMBER);
          await nextTick();

          expect(findVerifyCodeInput().props()).toMatchObject({
            arkoseChallengeShown: true,
            arkoseChallengeSolved: false,
            arkoseToken: '',
          });
        });

        describe('when the arkose challenge is solved', () => {
          it('passes correct arkose props to InternationalPhoneInput', async () => {
            findPhoneVerificationArkoseApp().vm.$emit('challenge-solved', MOCK_ARKOSE_TOKEN);
            await nextTick();

            expect(findInternationalPhoneInput().props()).toMatchObject({
              arkoseChallengeShown: true,
              arkoseChallengeSolved: true,
              arkoseToken: MOCK_ARKOSE_TOKEN,
            });
          });

          it('passes the correct arkose props to VerifyPhoneVerificationCode', async () => {
            findInternationalPhoneInput().vm.$emit('next', PHONE_NUMBER);
            await nextTick();

            findPhoneVerificationArkoseApp().vm.$emit('challenge-solved', MOCK_ARKOSE_TOKEN);
            await nextTick();

            expect(findVerifyCodeInput().props()).toMatchObject({
              arkoseChallengeShown: true,
              arkoseChallengeSolved: true,
              arkoseToken: MOCK_ARKOSE_TOKEN,
            });
          });

          it('passes resetSession prop as false to PhoneVerificationArkoseApp', async () => {
            findPhoneVerificationArkoseApp().vm.$emit('challenge-solved', MOCK_ARKOSE_TOKEN);
            await nextTick();

            expect(findPhoneVerificationArkoseApp().props()).toMatchObject({
              publicKey: MOCK_PUBLIC_KEY,
              domain: MOCK_DOMAIN,
              resetSession: false,
            });
          });
        });
      });

      describe('when verification attempts are greater than or equal to 3', () => {
        beforeEach(() => {
          createComponent({}, {}, { arkoseLabsPhoneVerificationChallenge: true });

          findInternationalPhoneInput().vm.$emit('verification-attempt');
          findInternationalPhoneInput().vm.$emit('verification-attempt');
          findInternationalPhoneInput().vm.$emit('verification-attempt');

          return nextTick();
        });

        it('shows phone verification arkose app with resetSession prop as true', () => {
          expect(findPhoneVerificationArkoseApp().exists()).toBe(true);

          expect(findPhoneVerificationArkoseApp().props()).toMatchObject({
            publicKey: MOCK_PUBLIC_KEY,
            domain: MOCK_DOMAIN,
            resetSession: true,
          });
        });
      });
    });
  });
});

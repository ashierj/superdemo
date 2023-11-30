import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';
import PhoneVerification from 'ee/users/identity_verification/components/phone_verification.vue';
import InternationalPhoneInput from 'ee/users/identity_verification/components/international_phone_input.vue';
import VerifyPhoneVerificationCode from 'ee/users/identity_verification/components/verify_phone_verification_code.vue';
import Captcha from 'ee/users/identity_verification/components/identity_verification_captcha.vue';

describe('Phone Verification component', () => {
  let wrapper;

  const PHONE_NUMBER = {
    country: 'US',
    internationalDialCode: '1',
    number: '555',
  };

  const findInternationalPhoneInput = () => wrapper.findComponent(InternationalPhoneInput);
  const findVerifyCodeInput = () => wrapper.findComponent(VerifyPhoneVerificationCode);
  const findPhoneExemptionLink = () =>
    wrapper.findByText(s__('IdentityVerification|Verify with a credit card instead?'));

  const findCaptcha = () => wrapper.findComponent(Captcha);

  const createComponent = (provide = {}, props = {}) => {
    wrapper = shallowMountExtended(PhoneVerification, {
      provide: {
        offerPhoneNumberExemption: true,
        phoneNumber: {
          enableArkoseChallenge: true,
          showArkoseChallenge: true,
          showRecaptchaChallenge: true,
        },
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

  describe('Captcha', () => {
    it('renders the phone verification captcha component', () => {
      expect(findCaptcha().exists()).toBe(true);

      expect(findCaptcha().props()).toMatchObject({
        enableArkoseChallenge: true,
        showArkoseChallenge: true,
        showRecaptchaChallenge: true,
        verificationAttempts: 0,
      });
    });

    describe('when `verification-attempt` event is emitted', () => {
      it('passes it as a prop to phone verification captcha component', async () => {
        findInternationalPhoneInput().vm.$emit('verification-attempt');
        await nextTick();

        expect(findCaptcha().props()).toMatchObject({
          verificationAttempts: 1,
        });
      });
    });

    describe('when `captcha-shown` event is emitted', () => {
      it('passes disableSubmitButton prop as true', async () => {
        findCaptcha().vm.$emit('captcha-shown');
        await nextTick();

        expect(findInternationalPhoneInput().props()).toMatchObject({
          disableSubmitButton: true,
        });
      });
    });

    describe('when `captcha-solved` event is emitted', () => {
      it('passes correct props', async () => {
        findCaptcha().vm.$emit('captcha-solved', { captcha_token: '1234' });
        await nextTick();

        expect(findInternationalPhoneInput().props()).toMatchObject({
          disableSubmitButton: false,
          additionalRequestParams: { captcha_token: '1234' },
        });
      });
    });

    describe('when `captcha-reset` event is emitted', () => {
      it('passes correct props', async () => {
        findCaptcha().vm.$emit('captcha-reset');
        await nextTick();

        expect(findInternationalPhoneInput().props()).toMatchObject({
          disableSubmitButton: true,
          additionalRequestParams: {},
        });
      });
    });
  });
});

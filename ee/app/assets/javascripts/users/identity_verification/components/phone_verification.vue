<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import InternationalPhoneInput from './international_phone_input.vue';
import VerifyPhoneVerificationCode from './verify_phone_verification_code.vue';
import Captcha from './identity_verification_captcha.vue';

export default {
  name: 'PhoneVerification',
  components: {
    GlButton,
    InternationalPhoneInput,
    VerifyPhoneVerificationCode,
    Captcha,
  },
  inject: ['phoneNumber', 'offerPhoneNumberExemption'],
  data() {
    return {
      stepIndex: 1,
      latestPhoneNumber: {},
      verificationAttempts: 0,
      disableSubmitButton: false,
      captchaData: {},
    };
  },
  methods: {
    goToStepTwo(phoneNumber) {
      this.stepIndex = 2;
      this.latestPhoneNumber = phoneNumber;
    },
    goToStepOne() {
      this.stepIndex = 1;
    },
    setVerified() {
      this.$emit('completed');
    },
    increaseVerificationAttempts() {
      this.verificationAttempts += 1;
    },
    onCaptchaShown() {
      this.disableSubmitButton = true;
    },
    onCaptchaSolved(data) {
      this.disableSubmitButton = false;
      this.captchaData = data;
    },
    onCaptchaReset() {
      this.disableSubmitButton = true;
      this.captchaData = {};
    },
  },
  i18n: {
    verifyWithCreditCard: s__('IdentityVerification|Verify with a credit card instead?'),
  },
};
</script>
<template>
  <div>
    <international-phone-input
      v-if="stepIndex == 1"
      :disable-submit-button="disableSubmitButton"
      :additional-request-params="captchaData"
      @next="goToStepTwo"
      @verification-attempt="increaseVerificationAttempts"
      @skip-verification="setVerified"
    >
      <template #captcha>
        <captcha
          :verification-attempts="verificationAttempts"
          :enable-arkose-challenge="phoneNumber.enableArkoseChallenge"
          :show-arkose-challenge="phoneNumber.showArkoseChallenge"
          :show-recaptcha-challenge="phoneNumber.showRecaptchaChallenge"
          @captcha-shown="onCaptchaShown"
          @captcha-solved="onCaptchaSolved"
          @captcha-reset="onCaptchaReset"
        />
      </template>
    </international-phone-input>

    <verify-phone-verification-code
      v-if="stepIndex == 2"
      :latest-phone-number="latestPhoneNumber"
      :disable-submit-button="disableSubmitButton"
      :additional-request-params="captchaData"
      @back="goToStepOne"
      @verification-attempt="increaseVerificationAttempts"
      @verified="setVerified"
    >
      <template #captcha>
        <captcha
          :verification-attempts="verificationAttempts"
          :enable-arkose-challenge="phoneNumber.enableArkoseChallenge"
          :show-arkose-challenge="phoneNumber.showArkoseChallenge"
          :show-recaptcha-challenge="phoneNumber.showRecaptchaChallenge"
          @captcha-shown="onCaptchaShown"
          @captcha-solved="onCaptchaSolved"
          @captcha-reset="onCaptchaReset"
        />
      </template>
    </verify-phone-verification-code>

    <gl-button
      v-if="offerPhoneNumberExemption"
      block
      variant="link"
      class="gl-mt-5 gl-font-sm"
      @click="$emit('exemptionRequested')"
      >{{ $options.i18n.verifyWithCreditCard }}</gl-button
    >
  </div>
</template>

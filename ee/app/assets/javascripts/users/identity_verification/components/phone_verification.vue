<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import PhoneVerificationArkoseApp from 'ee/arkose_labs/components/phone_verification_arkose_app.vue';
import InternationalPhoneInput from './international_phone_input.vue';
import VerifyPhoneVerificationCode from './verify_phone_verification_code.vue';

export default {
  name: 'PhoneVerification',
  components: {
    GlButton,
    InternationalPhoneInput,
    VerifyPhoneVerificationCode,
    PhoneVerificationArkoseApp,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['arkose', 'phoneNumber', 'offerPhoneNumberExemption'],
  data() {
    return {
      stepIndex: 1,
      latestPhoneNumber: {},
      arkoseChallengeSolved: false,
      arkoseToken: '',
      resetArkoseSession: false,
      verificationAttempts: 0,
    };
  },
  computed: {
    showArkoseChallenge() {
      return (
        this.glFeatures.arkoseLabsPhoneVerificationChallenge &&
        (this.phoneNumber.challengeUser || this.verificationAttempts >= 3)
      );
    },
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
    onArkoseChallengeSolved(arkoseToken) {
      this.arkoseChallengeSolved = true;
      this.arkoseToken = arkoseToken;
      this.resetArkoseSession = false;
    },
    increaseVerificationAttempts() {
      this.verificationAttempts += 1;

      this.arkoseChallengeSolved = false;
      this.arkoseToken = '';
      this.resetArkoseSession = true;
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
      :arkose-challenge-shown="showArkoseChallenge"
      :arkose-challenge-solved="arkoseChallengeSolved"
      :arkose-token="arkoseToken"
      @next="goToStepTwo"
      @verification-attempt="increaseVerificationAttempts"
      @skip-verification="setVerified"
    />

    <verify-phone-verification-code
      v-if="stepIndex == 2"
      :latest-phone-number="latestPhoneNumber"
      :arkose-challenge-shown="showArkoseChallenge"
      :arkose-challenge-solved="arkoseChallengeSolved"
      :arkose-token="arkoseToken"
      @back="goToStepOne"
      @verification-attempt="increaseVerificationAttempts"
      @verified="setVerified"
    />

    <gl-button
      v-if="offerPhoneNumberExemption"
      block
      variant="link"
      class="gl-mt-5 gl-font-sm"
      @click="$emit('exemptionRequested')"
      >{{ $options.i18n.verifyWithCreditCard }}</gl-button
    >

    <phone-verification-arkose-app
      v-if="showArkoseChallenge"
      :public-key="arkose.apiKey"
      :domain="arkose.domain"
      :reset-session="resetArkoseSession"
      class="gl-mt-5"
      @challenge-solved="onArkoseChallengeSolved"
    />
  </div>
</template>

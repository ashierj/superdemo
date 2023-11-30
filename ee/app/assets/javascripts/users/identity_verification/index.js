import Vue from 'vue';
import apolloProvider from 'ee/subscriptions/buy_addons_shared/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { getParsedDataset } from '~/pages/admin/application_settings/utils';
import IdentityVerificationWizard from './components/wizard.vue';

export const initIdentityVerification = () => {
  const el = document.getElementById('js-identity-verification');

  if (!el) return false;

  const {
    email,
    creditCard,
    phoneNumber,
    offerPhoneNumberExemption,
    verificationStatePath,
    phoneExemptionPath,
    arkose,
    successfulVerificationPath,
  } = convertObjectPropsToCamelCase(JSON.parse(el.dataset.data), { deep: true });

  const phoneNumberParsedData = getParsedDataset({
    dataset: phoneNumber,
    booleanAttributes: ['enableArkoseChallenge', 'showArkoseChallenge', 'showRecaptchaChallenge'],
  });

  return new Vue({
    el,
    apolloProvider,
    name: 'IdentityVerificationRoot',
    provide: {
      email,
      creditCard,
      phoneNumber: phoneNumberParsedData,
      offerPhoneNumberExemption,
      verificationStatePath,
      phoneExemptionPath,
      arkoseConfiguration: arkose,
      successfulVerificationPath,
    },
    render: (createElement) => createElement(IdentityVerificationWizard),
  });
};

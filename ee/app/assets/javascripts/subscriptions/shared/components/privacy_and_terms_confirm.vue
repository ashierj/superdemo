<script>
import { GlFormCheckbox, GlLink, GlSprintf } from '@gitlab/ui';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';
import { s__ } from '~/locale';

export default {
  name: 'PrivacyAndTermsConfirm',
  i18n: {
    label: s__(
      'Subscriptions|I accept the %{privacyLinkStart}Privacy Statement%{privacyLinkEnd} and %{termsLinkStart}Terms of Service%{termsLinkEnd}.',
    ),
  },
  helpLinks: {
    privacyLink: `${PROMO_URL}/privacy`,
    termsLink: `${PROMO_URL}/terms#subscription`,
  },
  components: { GlFormCheckbox, GlLink, GlSprintf },
  props: {
    value: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['input:value'],
  methods: {
    toogleAccepted(value) {
      this.$emit('input', value);
    },
  },
};
</script>
<template>
  <gl-form-checkbox :checked="value" @input="toogleAccepted">
    <gl-sprintf :message="$options.i18n.label">
      <template #privacyLink="{ content }">
        <gl-link
          :href="$options.helpLinks.privacyLink"
          target="_blank"
          data-testid="privacy-link"
          >{{ content }}</gl-link
        >
      </template>
      <template #termsLink="{ content }">
        <gl-link :href="$options.helpLinks.termsLink" target="_blank" data-testid="terms-link">{{
          content
        }}</gl-link>
      </template>
    </gl-sprintf>
  </gl-form-checkbox>
</template>

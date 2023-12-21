<script>
import { s__ } from '~/locale';
import getBillingAccountQuery from 'ee/vue_shared/purchase_flow/graphql/queries/get_billing_account.customer.query.graphql';
import { CUSTOMERSDOT_CLIENT } from 'ee/subscriptions/buy_addons_shared/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { logError } from '~/lib/logger';

export default {
  data() {
    return {
      billingAccount: null,
    };
  },
  apollo: {
    billingAccount: {
      query: getBillingAccountQuery,
      client: CUSTOMERSDOT_CLIENT,
      skip() {
        return !gon.features?.keyContactsManagement;
      },
      error(error) {
        this.handleError(error);
      },
    },
  },
  computed: {
    shouldShowInformation() {
      return Boolean(this.billingAccount?.zuoraAccountName);
    },
  },
  methods: {
    handleError(error) {
      Sentry.captureException(error);
      logError(error);
    },
  },
  i18n: {
    title: s__('Checkout|Company information'),
    taxId: s__('Checkout|Tax ID'),
  },
};
</script>
<template>
  <div v-if="shouldShowInformation" class="gl-mb-5" data-testid="billing-account-company-wrapper">
    <h6>{{ $options.i18n.title }}</h6>

    <div data-testid="billing-account-company-name">{{ billingAccount.zuoraAccountName }}</div>
    <div v-if="billingAccount.vatFieldVisible" data-testid="billing-account-tax-id">
      {{ $options.i18n.taxId }}: {{ billingAccount.zuoraAccountVatId }}
    </div>
  </div>
</template>

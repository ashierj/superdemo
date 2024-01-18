<script>
import CompanyInformation from 'ee/vue_shared/purchase_flow/components/company_information.vue';
import ContactBillingAddress from 'ee/vue_shared/purchase_flow/components/contact_billing_address.vue';

export default {
  components: {
    CompanyInformation,
    ContactBillingAddress,
  },
  props: {
    billingAccount: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <div>
    <contact-billing-address :is-sold-to-contact="true" :contact="billingAccount.soldToContact" />
    <contact-billing-address :is-sold-to-contact="false" :contact="billingAccount.billToContact" />

    <company-information :billing-account="billingAccount" />
  </div>
</template>

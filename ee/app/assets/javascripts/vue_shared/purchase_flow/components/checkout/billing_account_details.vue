<script>
import CompanyInformation from 'ee/vue_shared/purchase_flow/components/company_information.vue';
import ContactBillingAddress from 'ee/vue_shared/purchase_flow/components/contact_billing_address.vue';

export default {
  components: {
    CompanyInformation,
    ContactBillingAddress,
  },
  props: {
    soldToContact: {
      type: Object,
      required: true,
    },
    billToContact: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <div>
    <contact-billing-address :is-sold-to-contact="true" :contact="soldToContact" />
    <contact-billing-address :is-sold-to-contact="false" :contact="billToContact" />

    <company-information />
  </div>
</template>

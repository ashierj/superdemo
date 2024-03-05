<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import GcIamForm from '../google_cloud_iam/form.vue';

export default {
  name: 'IntegrationSectionGoogleCloudIAM',
  components: {
    GcIamForm,
  },
  computed: {
    ...mapGetters(['propsSource']),
    dynamicFields() {
      return this.propsSource.fields;
    },
  },
};
</script>

<template>
  <div>
    <gc-iam-form :fields="dynamicFields" />
  </div>
</template>

<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import {
  STATE_EMPTY,
  STATE_FORM,
  STATE_GUIDED,
  STATE_INITIAL,
  STATE_MANUAL,
} from '../google_cloud_iam/constants';
import EmptyState from '../google_cloud_iam/empty_state.vue';
import GcIamForm from '../google_cloud_iam/form.vue';
import GuidedSetup from '../google_cloud_iam/guided_setup.vue';
import ManualSetup from '../google_cloud_iam/manual_setup.vue';

export default {
  name: 'IntegrationSectionGoogleCloudIAM',
  components: {
    EmptyState,
    GcIamForm,
    GuidedSetup,
    ManualSetup,
  },
  data() {
    return {
      show: STATE_INITIAL,
    };
  },
  computed: {
    ...mapGetters(['propsSource']),
    dynamicFields() {
      return this.propsSource.fields;
    },
    isEditable() {
      return [STATE_FORM, STATE_MANUAL].includes(this.show);
    },
    isFormEmpty() {
      return this.propsSource.fields.every((field) => !field.value);
    },
  },
  watch: {
    isEditable: {
      handler(editable) {
        this.propsSource.editable = editable;
      },
      immediate: true,
    },
  },
  created() {
    this.show = this.isFormEmpty ? 'empty' : 'form';
  },
  methods: {
    onShow(type) {
      this.show = type;
    },
  },
  STATE_EMPTY,
  STATE_GUIDED,
  STATE_MANUAL,
};
</script>

<template>
  <div aria-live="polite">
    <empty-state v-if="show === $options.STATE_EMPTY" @show="onShow" />
    <guided-setup v-else-if="show === $options.STATE_GUIDED" @show="onShow" />
    <manual-setup v-else-if="show === $options.STATE_MANUAL" @show="onShow" />

    <gc-iam-form v-if="isEditable" :fields="dynamicFields" />
  </div>
</template>

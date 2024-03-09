<script>
import ValueStreamForm from './value_stream_form.vue';

export default {
  name: 'VSASettingsApp',
  components: {
    ValueStreamForm,
  },
  props: {
    isEditPage: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <value-stream-form :is-editing="isEditPage" />
</template>

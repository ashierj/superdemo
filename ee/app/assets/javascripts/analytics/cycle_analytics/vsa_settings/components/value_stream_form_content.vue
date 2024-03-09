<script>
import { PRESET_OPTIONS_DEFAULT } from 'ee/analytics/cycle_analytics/components/create_value_stream_form/constants';
import ValueStreamFormContentHeader from './value_stream_form_content_header.vue';

export default {
  name: 'ValueStreamFormContent',
  components: {
    ValueStreamFormContentHeader,
  },
  props: {
    initialData: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    initialPreset: {
      type: String,
      required: false,
      default: PRESET_OPTIONS_DEFAULT,
    },
    initialFormErrors: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    defaultStageConfig: {
      type: Array,
      required: true,
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
    valueStreamPath: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>
<template>
  <div>
    <value-stream-form-content-header
      :is-editing="isEditing"
      :value-stream-path="valueStreamPath"
    />
  </div>
</template>

<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import { i18n } from 'ee/analytics/cycle_analytics/components/create_value_stream_form/constants';

const { FORM_TITLE, EDIT_FORM_TITLE, EDIT_FORM_ACTION } = i18n;

export default {
  name: 'ValueStreamFormContentHeader',
  components: {
    GlButton,
  },
  props: {
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLoading: {
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
  i18n: {
    createValueStream: FORM_TITLE,
    editValueStreamTitle: EDIT_FORM_TITLE,
    saveValueStreamAction: EDIT_FORM_ACTION,
    viewValueStreamAction: s__('ValueStreamAnalytics|View value stream'),
  },
  computed: {
    primaryButtonText() {
      return this.isEditing
        ? this.$options.i18n.saveValueStreamAction
        : this.$options.i18n.createValueStream;
    },
    formTitle() {
      return this.isEditing
        ? this.$options.i18n.editValueStreamTitle
        : this.$options.i18n.createValueStream;
    },
  },
};
</script>

<template>
  <header
    class="page-title gl-display-flex gl-gap-5 gl-flex-wrap gl-align-items-center gl-justify-content-space-between"
  >
    <h1 data-testid="value-stream-form-title" class="gl-font-size-h-display gl-my-0">
      {{ formTitle }}
    </h1>
    <div class="gl-display-flex gl-gap-5">
      <gl-button
        v-if="isEditing"
        category="secondary"
        variant="confirm"
        :href="valueStreamPath"
        :disabled="isLoading"
        >{{ $options.i18n.viewValueStreamAction }}</gl-button
      >
      <gl-button
        data-testid="value-stream-form-primary-btn"
        variant="confirm"
        :loading="isLoading"
        @click="$emit('clickedPrimaryAction')"
        >{{ primaryButtonText }}</gl-button
      >
    </div>
  </header>
</template>

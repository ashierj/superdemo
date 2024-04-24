<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import Tracking from '~/tracking';

export default {
  name: 'HandRaiseLeadButton',
  components: {
    GlButton,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [Tracking.mixin()],
  props: {
    ctaTracking: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    modalId: {
      type: String,
      required: true,
    },
    buttonText: {
      type: String,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    buttonAttributes: {
      type: Object,
      required: true,
    },
  },
  computed: {
    tracking() {
      return {
        label: 'hand_raise_lead_form',
        experiment: this.ctaTracking.experiment,
      };
    },
  },
  methods: {
    trackBtnClick() {
      const { action, ...options } = this.ctaTracking;
      if (action) {
        this.track(action, options);
      }
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-modal="modalId"
    v-bind="buttonAttributes"
    :loading="isLoading"
    @click="trackBtnClick"
  >
    {{ buttonText }}
  </gl-button>
</template>

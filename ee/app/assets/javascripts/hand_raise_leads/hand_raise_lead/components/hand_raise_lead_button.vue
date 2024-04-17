<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import Tracking from '~/tracking';
import { PQL_BUTTON_TEXT } from '../constants';
import HandRaiseLeadModal from './hand_raise_lead_modal.vue';

export default {
  name: 'HandRaiseLeadButton',
  components: {
    GlButton,
    HandRaiseLeadModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [Tracking.mixin()],
  inject: {
    createHandRaiseLeadPath: {},
    user: {
      default: {},
    },
    buttonAttributes: {
      default: {},
    },
    buttonText: {
      default: PQL_BUTTON_TEXT,
    },
    ctaTracking: {
      default: {},
    },
  },
  data() {
    return { isLoading: false, modalId: uniqueId('hand-raise-lead-modal-') };
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
    updateLoading(value) {
      this.isLoading = value;
    },
  },
};
</script>

<template>
  <div>
    <gl-button
      v-gl-modal="modalId"
      v-bind="buttonAttributes"
      :loading="isLoading"
      @click="trackBtnClick"
    >
      {{ buttonText }}
    </gl-button>

    <hand-raise-lead-modal
      :user="user"
      :submit-path="createHandRaiseLeadPath"
      :cta-tracking="ctaTracking"
      :modal-id="modalId"
      @loading="updateLoading"
    />
  </div>
</template>

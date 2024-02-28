<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlModal } from '@gitlab/ui';
import VulnerabilityDetails from 'ee/vue_shared/security_reports/components/vulnerability_details.vue';
import { VULNERABILITY_MODAL_ID } from './constants';

export default {
  VULNERABILITY_MODAL_ID,
  components: {
    GlModal,
    VulnerabilityDetails,
  },
  props: {
    modal: {
      type: Object,
      required: true,
    },
    canCreateIssue: {
      type: Boolean,
      required: false,
      default: false,
    },
    canDismissVulnerability: {
      type: Boolean,
      required: false,
      default: false,
    },
    isCreatingIssue: {
      type: Boolean,
      required: true,
    },
    isDismissingVulnerability: {
      type: Boolean,
      required: true,
    },
    isCreatingMergeRequest: {
      type: Boolean,
      required: true,
    },
    isLoadingAdditionalInfo: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    vulnerability() {
      return this.modal.vulnerability;
    },
  },
};
</script>
<template>
  <gl-modal
    ref="modal"
    :modal-id="$options.VULNERABILITY_MODAL_ID"
    :title="modal.title"
    size="lg"
    data-testid="vulnerability-modal-content"
    class="modal-security-report-dast"
    v-bind="$attrs"
    @hidden="$emit('hidden')"
  >
    <slot>
      <vulnerability-details :vulnerability="vulnerability" class="js-vulnerability-details" />
    </slot>
  </gl-modal>
</template>

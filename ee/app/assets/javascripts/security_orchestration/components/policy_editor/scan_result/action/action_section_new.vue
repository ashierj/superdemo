<script>
import { REQUIRE_APPROVAL_TYPE } from '../lib';
import ApproverAction from './approver_action.vue';
import BotCommentAction from './bot_comment_action.vue';

export default {
  name: 'ActionSection',
  components: {
    ApproverAction,
    BotCommentAction,
  },
  props: {
    errors: {
      type: Array,
      required: false,
      default: () => [],
    },
    initAction: {
      type: Object,
      required: true,
    },
    existingApprovers: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isApproverAction() {
      return this.initAction.type === REQUIRE_APPROVAL_TYPE;
    },
  },
};
</script>

<template>
  <approver-action
    v-if="isApproverAction"
    class="gl-mb-4"
    :init-action="initAction"
    :errors="errors.action"
    :existing-approvers="existingApprovers"
    @error="$emit('error')"
    @updateApprovers="$emit('updateApprovers', $event)"
    @changed="$emit('changed', $event)"
    @remove="$emit('remove')"
  />
  <bot-comment-action v-else class="gl-mb-4" :init-action="initAction" @remove="$emit('remove')" />
</template>

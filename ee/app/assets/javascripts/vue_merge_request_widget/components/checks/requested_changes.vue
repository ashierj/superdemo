<script>
import { GlIcon, GlPopover, GlButton, GlModal } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import mergeRequestQueryVariablesMixin from '~/vue_merge_request_widget/mixins/merge_request_query_variables';
import ActionButtons from '~/vue_merge_request_widget/components/action_buttons.vue';
import MergeChecksMessage from '~/vue_merge_request_widget/components/checks/message.vue';
import requestedChangesQuery from './queries/requested_changes.query.graphql';
import updateMergeRequestMutation from './queries/update_merge_request.mutation.graphql';

export default {
  name: 'MergeChecksUnresolvedDiscussions',
  components: {
    GlIcon,
    GlPopover,
    GlButton,
    GlModal,
    MergeChecksMessage,
    ActionButtons,
  },
  mixins: [mergeRequestQueryVariablesMixin],
  apollo: {
    state: {
      query: requestedChangesQuery,
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data?.project?.mergeRequest,
    },
  },
  props: {
    mr: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    check: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      state: {},
      updating: false,
      showConfirmModal: false,
    };
  },
  computed: {
    canMerge() {
      return this.state.userPermissions?.canMerge;
    },
    overrideRequestedChanges() {
      return this.check.status === 'WARNING';
    },
    actionButtonText() {
      if (this.overrideRequestedChanges) {
        return s__('mrWidget|Bypassed');
      }

      if (!this.canMerge) {
        return s__("mrWidget|Can't bypass");
      }

      return s__('mrWidget|Bypass');
    },
    tertiaryActionsButtons() {
      return [
        {
          text: this.actionButtonText,
          category: 'default',
          loading: this.$apollo.queries.state.loading || this.updating,
          disabled: !this.canMerge,
          onClick: () => {
            this.showConfirmModal = true;
          },
        },
      ].filter((x) => x);
    },
    warningTertiaryActionsButtons() {
      return [
        {
          text: this.actionButtonText,
          disabled: true,
        },
        this.canMerge && {
          text: __('Remove'),
          category: 'default',
          loading: this.updating,
          onClick: () => {
            this.showConfirmModal = true;
          },
        },
      ].filter((x) => x);
    },
  },
  methods: {
    async updateMergeRequest() {
      this.updating = true;

      await this.$apollo.mutate({
        mutation: updateMergeRequestMutation,
        variables: {
          ...this.mergeRequestQueryVariables,
          overrideRequestedChanges: !this.overrideRequestedChanges,
        },
      });

      this.updating = false;
    },
  },
  modalPrimaryActionBypass: {
    text: s__('mrWidget|Bypass'),
  },
  modalPrimaryActionRemove: {
    text: __('Remove'),
  },
  modalSecondaryAction: {
    text: __('Cancel'),
    attributes: {
      variant: 'default',
    },
  },
  i18n: {
    permissionToMergeHelpText: __(
      'Users who can merge this merge request can override the request for changes, and unblock this merge request.',
    ),
    invalidPermissionHelpText: __(
      "You can't override the request for changes because you don't have permission to merge this merge request. To override, ask someone who is eligible to merge this merge request.",
    ),
    removeOverrideWarningText: __(
      'Removing the bypass will cause the merge request to be blocked if any reviews have requested changes.',
    ),
    overrideWarningText: __(
      'Bypassing blocking reviews will allow the merge request to be merged even if any reviewer has requested changes. This applies to future reviews as well.',
    ),
  },
};
</script>

<template>
  <merge-checks-message :check="check">
    <template #failed>
      <action-buttons :tertiary-buttons="tertiaryActionsButtons" />
    </template>
    <template #warning>
      <action-buttons :tertiary-buttons="warningTertiaryActionsButtons" />
    </template>
    <template v-if="check.status === 'WARNING' || check.status === 'FAILED'">
      <gl-button variant="link" class="gl-mr-3" :aria-label="__('Learn more')">
        <gl-icon id="changes-requested-help" name="information-o" />
      </gl-button>
      <gl-popover target="changes-requested-help" placement="top">
        <template #title>{{ __('Bypass requested changes') }}</template>
        <p class="gl-mb-0">
          <template v-if="canMerge">
            {{ $options.i18n.permissionToMergeHelpText }}
          </template>
          <template v-else>
            {{ $options.i18n.invalidPermissionHelpText }}
          </template>
        </p>
      </gl-popover>
      <gl-modal
        v-model="showConfirmModal"
        modal-id="requested-changes-modal"
        :action-primary="
          overrideRequestedChanges
            ? $options.modalPrimaryActionRemove
            : $options.modalPrimaryActionBypass
        "
        :action-secondary="$options.modalSecondaryAction"
        :title="overrideRequestedChanges ? __('Remove bypass') : __('Bypass blocking reviews')"
        @primary="updateMergeRequest"
      >
        <template v-if="overrideRequestedChanges">
          {{ $options.i18n.removeOverrideWarningText }}
        </template>
        <template v-else>
          {{ $options.i18n.overrideWarningText }}
        </template>
      </gl-modal>
    </template>
  </merge-checks-message>
</template>

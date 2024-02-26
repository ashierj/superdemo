<script>
import { GlModal } from '@gitlab/ui';
import { __, s__ } from '~/locale';

export default {
  name: 'CustomRolesDeleteModal',
  i18n: {
    title: s__('MemberRole|Delete custom role?'),
    modalBody: s__(
      'MemberRole|Are you sure you want to delete this custom role? Before you delete this custom role, make sure no group member has this role.',
    ),
  },
  components: {
    GlModal,
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
  },
  primaryActionProps: {
    text: s__('MemberRole|Delete role'),
    attributes: { variant: 'danger' },
  },
  cancelActionProps: {
    text: __('Cancel'),
  },
};
</script>

<template>
  <gl-modal
    modal-id="custom-roles-delete-modal"
    :visible="visible"
    :title="$options.i18n.title"
    :action-primary="$options.primaryActionProps"
    :action-cancel="$options.cancelActionProps"
    size="sm"
    @primary="$emit('delete')"
    @hidden="$emit('cancel')"
  >
    {{ $options.i18n.modalBody }}
  </gl-modal>
</template>

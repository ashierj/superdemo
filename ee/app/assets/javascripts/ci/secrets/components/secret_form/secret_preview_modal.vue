<script>
import { GlModal } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { localeDateFormat } from '~/lib/utils/datetime_utility';

export default {
  name: 'SecretPreviewModal',
  components: {
    GlModal,
  },
  props: {
    createdAt: {
      type: Number,
      required: true,
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
    expiration: {
      type: Date,
      required: false,
      default: null,
    },
    isVisible: {
      type: Boolean,
      required: true,
    },
    secretKey: {
      type: String,
      required: false,
      default: '',
    },
    rotationPeriod: {
      type: String,
      required: false,
      default: '',
    },
    isEditing: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    formattedCreatedAt() {
      return localeDateFormat.asDateTimeFull.format(this.createdAt);
    },
    formattedExpiration() {
      if (!this.expiration) {
        return __('None');
      }

      return localeDateFormat.asDateTimeFull.format(this.expiration);
    },
    actionPrimaryAttributes() {
      return {
        text: this.isEditing ? __('Save changes') : s__('Secrets|Add secret'),
        attributes: {
          variant: 'confirm',
        },
      };
    },
    title() {
      return sprintf(s__('Secrets|Preview for %{secretKey}'), { secretKey: this.secretKey });
    },
  },
  actionSecondary: {
    text: __('Go back to edit'),
    attributes: {
      variant: 'default',
    },
  },
};
</script>
<template>
  <gl-modal
    modal-id="ci-secret-preview-modal"
    :visible="isVisible"
    :title="title"
    :action-primary="actionPrimaryAttributes"
    :action-cancel="$options.actionSecondary"
    size="sm"
    @primary="$emit('submit-secret')"
    @canceled="$emit('hide-preview-modal')"
    @change="$emit('hide-preview-modal')"
  >
    <p class="gl-font-weight-bold">{{ __('Created on') }}</p>
    <p data-testid="secret-preview-created-at">{{ formattedCreatedAt }}</p>
    <p class="gl-font-weight-bold">{{ __('Description') }}</p>
    <p data-testid="secret-preview-description">{{ description }}</p>
    <p class="gl-font-weight-bold">{{ __('Expiration date') }}</p>
    <p data-testid="secret-preview-expiration">{{ formattedExpiration }}</p>
    <p class="gl-font-weight-bold">{{ __('Rotation schedule') }}</p>
    <p data-testid="secret-preview-rotation-period">{{ rotationPeriod }}</p>
    <p class="gl-font-weight-bold">{{ __('Access permission') }}</p>
    <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
    <!-- TODO: Replace dummy text with access permission data -->
    <p>Maintainers can read and edit</p>
    <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
  </gl-modal>
</template>

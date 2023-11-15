<script>
import { GlButton } from '@gitlab/ui';

export default {
  name: 'SecretForm',
  components: {
    GlButton,
  },
  props: {
    submitButtonText: {
      type: String,
      required: true,
    },
    redirectToRouteName: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div>
    <gl-button :to="{ name: redirectToRouteName }" class="gl-float-right gl-my-4">
      {{ submitButtonText }}
    </gl-button>
  </div>
</template>

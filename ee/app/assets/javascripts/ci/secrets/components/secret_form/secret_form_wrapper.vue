<script>
import { sprintf, s__ } from '~/locale';
import { INDEX_ROUTE_NAME, DETAILS_ROUTE_NAME } from '../../constants';
import SecretForm from './secret_form.vue';

export default {
  name: 'SecretFormWrapper',
  components: {
    SecretForm,
  },
  props: {
    secretKey: {
      type: String,
      required: true,
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    editPageTitle() {
      return sprintf(s__('Secrets|Edit %{key}'), { key: this.secretKey });
    },
  },
  INDEX_ROUTE_NAME,
  DETAILS_ROUTE_NAME,
};
</script>
<template>
  <div>
    <template v-if="!isEditing">
      <h1>{{ s__('Secrets|New secret') }}</h1>
      <p>
        {{
          s__(
            'Secrets|Add a new secret to the group by following the instructions in the form below.',
          )
        }}
      </p>
    </template>

    <h1 v-if="isEditing">
      {{ editPageTitle }}
    </h1>

    <secret-form
      :submit-button-text="isEditing ? __('Save changes') : s__('Secrets|Add secret')"
      :redirect-to-route-name="isEditing ? $options.DETAILS_ROUTE_NAME : $options.INDEX_ROUTE_NAME"
    />
  </div>
</template>

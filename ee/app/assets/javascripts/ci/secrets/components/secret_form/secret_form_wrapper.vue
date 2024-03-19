<script>
import { sprintf, s__ } from '~/locale';
import { DETAILS_ROUTE_NAME, ENTITY_PROJECT, INDEX_ROUTE_NAME } from '../../constants';
import SecretForm from './secret_form.vue';

const i18n = {
  descriptionGroup: s__(
    'Secrets|Add a new secret to the group by following the instructions in the form below.',
  ),
  descriptionProject: s__(
    'Secrets|Add a new secret to the project by following the instructions in the form below.',
  ),
  titleNew: s__('Secrets|New secret'),
};

export default {
  name: 'SecretFormWrapper',
  components: {
    SecretForm,
  },
  props: {
    entity: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: false,
      default: null,
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
    secretKey: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      environments: [],
    };
  },
  computed: {
    areEnvironmentsLoading() {
      // TODO: set value from environments query
      return true;
    },
    pageDescription() {
      if (this.entity === ENTITY_PROJECT) {
        return this.$options.i18n.descriptionProject;
      }

      return this.$options.i18n.descriptionGroup;
    },
    pageTitle() {
      if (this.isEditing) {
        return sprintf(s__('Secrets|Edit %{key}'), { key: this.secretKey });
      }

      return this.$options.i18n.titleNew;
    },
  },
  INDEX_ROUTE_NAME,
  DETAILS_ROUTE_NAME,
  i18n,
};
</script>
<template>
  <div>
    <h1 class="page-title gl-font-size-h-display">{{ pageTitle }}</h1>
    <p v-if="!isEditing">{{ pageDescription }}</p>
    <secret-form
      :are-environments-loading="areEnvironmentsLoading"
      :environments="environments"
      :is-editing="isEditing"
      :redirect-to-route-name="isEditing ? $options.DETAILS_ROUTE_NAME : $options.INDEX_ROUTE_NAME"
    />
  </div>
</template>

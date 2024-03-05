<script>
import { GlFormFields, GlButton, GlFormTextarea, GlForm, GlAlert } from '@gitlab/ui';
import { I18N_AGENT_NAME_LABEL, I18N_PROMPT_LABEL } from '../constants';

export default {
  components: {
    GlFormFields,
    GlButton,
    GlFormTextarea,
    GlForm,
    GlAlert,
  },
  inject: ['projectPath'],
  I18N_AGENT_NAME_LABEL,
  I18N_PROMPT_LABEL,
  formId: 'ai_agent_form',
  props: {
    buttonLabel: {
      type: String,
      required: true,
    },
    errorMessage: {
      type: String,
      required: false,
      default: '',
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    agentId: {
      type: String,
      required: false,
      default: '',
    },
    agentNameValue: {
      type: String,
      required: false,
      default: '',
    },
    agentPromptValue: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      fields: {
        name: {
          label: I18N_AGENT_NAME_LABEL,
          inputAttrs: {
            'data-testid': 'agent-name',
          },
        },
        prompt: {
          label: I18N_PROMPT_LABEL,
        },
      },
      formValues: {
        name: this.agentNameValue,
        prompt: this.agentPromptValue,
      },
    };
  },
  methods: {
    onSubmit() {
      this.$emit('submit', {
        projectPath: this.projectPath,
        agentId: this.agentId,
        name: this.formValues.name,
        prompt: this.formValues.prompt,
      });
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="errorMessage" :dismissible="false" variant="danger" class="gl-mb-3">
      {{ errorMessage }}
    </gl-alert>

    <gl-form @submit.prevent="onSubmit">
      <gl-form-fields v-model="formValues" :fields="fields" :form-id="$options.formId">
        <template #input(prompt)="{ id, value, input }">
          <gl-form-textarea :id="id" :value="value" @input="input" />
        </template>
      </gl-form-fields>
      <gl-button type="submit" variant="confirm" :loading="loading">{{ buttonLabel }}</gl-button>
    </gl-form>
  </div>
</template>

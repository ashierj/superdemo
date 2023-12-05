<script>
import {
  GlAlert,
  GlButton,
  GlCollapse,
  GlForm,
  GlFormCheckbox,
  GlFormGroup,
  GlFormInput,
  GlLink,
  GlLoadingIcon,
  GlSprintf,
  GlPopover,
} from '@gitlab/ui';
import { debounce } from 'lodash';

import { helpPagePath } from '~/helpers/help_page_helper';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS as DEBOUNCE_DELAY } from '~/lib/utils/constants';
import { validateHexColor } from '~/lib/utils/color_utils';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import ColorPicker from '~/vue_shared/components/color_picker/color_picker.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { __, s__ } from '~/locale';

import getComplianceFrameworkQuery from 'ee/graphql_shared/queries/get_compliance_framework.query.graphql';
import { SAVE_ERROR } from 'ee/groups/settings/compliance_frameworks/constants';
import {
  getSubmissionParams,
  initialiseFormData,
  fetchPipelineConfigurationFileExists,
  validatePipelineConfirmationFormat,
} from 'ee/groups/settings/compliance_frameworks/utils';

import createComplianceFrameworkMutation from '../../graphql/mutations/create_compliance_framework.mutation.graphql';
import updateComplianceFrameworkMutation from '../../graphql/mutations/update_compliance_framework.mutation.graphql';

export default {
  components: {
    ColorPicker,
    GlAlert,
    GlButton,
    GlCollapse,
    GlForm,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    GlPopover,
  },
  inject: ['pipelineConfigurationFullPathEnabled', 'pipelineConfigurationEnabled', 'groupPath'],
  data() {
    return {
      errorMessage: '',
      formData: initialiseFormData(),
      saving: false,
    };
  },
  apollo: {
    namespace: {
      query: getComplianceFrameworkQuery,
      variables() {
        return {
          fullPath: this.groupPath,
          complianceFramework: this.graphqlId,
        };
      },
      result({ data }) {
        const [complianceFramework] = data?.namespace.complianceFrameworks?.nodes || [];
        if (complianceFramework) {
          this.formData = { ...complianceFramework };
        } else {
          this.errorMessage = this.$options.i18n.fetchError;
        }
      },
      error(error) {
        this.errorMessage = this.$options.i18n.fetchError;
        Sentry.captureException(error);
      },
      skip() {
        return this.isNewFramework;
      },
    },
  },
  computed: {
    isNewFramework() {
      return !this.$route.params.id;
    },

    title() {
      return this.isNewFramework
        ? this.$options.i18n.addFrameworkTitle
        : this.$options.i18n.editFrameworkTitle;
    },

    saveButtonText() {
      return this.isNewFramework
        ? this.$options.i18n.addSaveBtnText
        : this.$options.i18n.editSaveBtnText;
    },

    graphqlId() {
      return this.$route.params.id
        ? convertToGraphQLId('ComplianceManagement::Framework', this.$route.params.id)
        : null;
    },

    isLoading() {
      return this.$apollo.loading || this.saving;
    },
    isValidColor() {
      return validateHexColor(this.formData.color);
    },

    isValidName() {
      if (this.formData.name === null) {
        return null;
      }

      return Boolean(this.formData.name);
    },

    isValidDescription() {
      if (this.formData.description === null) {
        return null;
      }

      return Boolean(this.formData.description);
    },

    isValidPipelineConfiguration() {
      if (!this.formData.pipelineConfigurationFullPath) {
        return null;
      }

      return this.isValidPipelineConfigurationFormat && this.pipelineConfigurationFileExists;
    },

    isValidPipelineConfigurationFormat() {
      return validatePipelineConfirmationFormat(this.formData.pipelineConfigurationFullPath);
    },

    disableSubmitBtn() {
      return (
        !this.isValidName ||
        !this.isValidDescription ||
        !this.isValidColor ||
        this.isValidPipelineConfiguration === false
      );
    },

    pipelineConfigurationFeedbackMessage() {
      if (!this.isValidPipelineConfigurationFormat) {
        return this.$options.i18n.pipelineConfigurationInputInvalidFormat;
      }

      return this.$options.i18n.pipelineConfigurationInputUnknownFile;
    },

    compliancePipelineConfigurationHelpPath() {
      return helpPagePath('user/group/compliance_frameworks.md', {
        anchor: 'example-configuration',
      });
    },
  },

  watch: {
    'formData.pipelineConfigurationFullPath': {
      handler(path) {
        if (path) {
          this.validatePipelineInput(path);
        }
      },
    },
  },

  methods: {
    setError(error, userFriendlyText) {
      this.saving = false;
      this.errorMessage = userFriendlyText;
      Sentry.captureException(error);
    },
    onCancel() {
      this.$router.back();
    },

    async onSubmit() {
      this.saving = true;
      this.errorMessage = '';
      try {
        const params = getSubmissionParams(
          this.formData,
          this.pipelineConfigurationFullPathEnabled,
        );

        const mutation = this.isNewFramework
          ? createComplianceFrameworkMutation
          : updateComplianceFrameworkMutation;
        const extraInput = this.isNewFramework
          ? { namespacePath: this.groupPath }
          : { id: this.graphqlId };
        const { data } = await this.$apollo.mutate({
          mutation,
          variables: {
            input: {
              ...extraInput,
              params,
            },
          },
          awaitRefetchQueries: true,
          refetchQueries: [
            {
              query: getComplianceFrameworkQuery,
              variables: {
                fullPath: this.groupPath,
              },
            },
          ],
        });

        const [error] = data?.createComplianceFramework?.errors || [];

        if (error) {
          this.setError(new Error(error), error);
        } else {
          this.$router.back();
        }
      } catch (e) {
        this.setError(e, SAVE_ERROR);
      }
    },

    async validatePipelineConfigurationPath(path) {
      this.pipelineConfigurationFileExists = await fetchPipelineConfigurationFileExists(path);
    },
    validatePipelineInput: debounce(function debounceValidation(path) {
      this.validatePipelineConfigurationPath(path);
    }, DEBOUNCE_DELAY),
  },

  i18n: {
    addFrameworkTitle: s__('ComplianceFrameworks|Create a compliance framework'),
    editFrameworkTitle: s__('ComplianceFrameworks|Edit a compliance framework'),

    submitButtonText: s__('ComplianceFrameworks|Add framework'),

    successMessageText: s__('ComplianceFrameworks|Compliance framework created'),
    titleInputLabel: s__('ComplianceFrameworks|Name'),
    titleInputInvalid: s__('ComplianceFrameworks|Name is required'),
    descriptionInputLabel: s__('ComplianceFrameworks|Description'),
    descriptionInputInvalid: s__('ComplianceFrameworks|Description is required'),
    pipelineConfigurationInputLabel: s__(
      'ComplianceFrameworks|Compliance pipeline configuration (optional)',
    ),
    pipelineConfigurationInputDescription: s__(
      'ComplianceFrameworks|Required format: %{codeStart}path/file.y[a]ml@group-name/project-name%{codeEnd}. %{linkStart}See some examples%{linkEnd}.',
    ),
    pipelineConfigurationInputDisabledPopoverTitle: s__(
      'ComplianceFrameworks|Requires Ultimate subscription',
    ),
    pipelineConfigurationInputDisabledPopoverContent: s__(
      'ComplianceFrameworks|Set compliance pipeline configuration for projects that use this framework. %{linkStart}How do I create the configuration?%{linkEnd}',
    ),
    pipelineConfigurationInputDisabledPopoverLink: helpPagePath(
      'user/group/compliance_frameworks.html#compliance-pipelines',
    ),
    pipelineConfigurationInputInvalidFormat: s__('ComplianceFrameworks|Invalid format'),
    pipelineConfigurationInputUnknownFile: s__('ComplianceFrameworks|Configuration not found'),
    colorInputLabel: s__('ComplianceFrameworks|Background color'),

    editSaveBtnText: __('Save changes'),
    addSaveBtnText: s__('ComplianceFrameworks|Add framework'),
    fetchError: s__(
      'ComplianceFrameworks|Error fetching compliance frameworks data. Please refresh the page or try a different framework',
    ),
  },
  disabledPipelineConfigurationInputPopoverTarget:
    'disabled-pipeline-configuration-input-popover-target',
};
</script>

<template>
  <div class="gl-border-t-1 gl-border-t-solid gl-border-t-gray-100 gl-pt-5">
    <gl-alert v-if="errorMessage" class="gl-mb-5" variant="danger" :dismissible="false">
      {{ errorMessage }}
    </gl-alert>
    <gl-loading-icon v-if="isLoading" size="lg" />

    <template v-else>
      <h2>{{ title }}</h2>

      <gl-form @submit.prevent="onSubmit">
        <div class="gl-display-flex gl-bg-gray-10 gl-p-4 gl-my-4 gl-align-items-start">
          <div class="gl-flex-grow-1">
            <div class="gl-font-weight-bold gl-font-size-h2">
              {{ s__('ComplianceFrameworks|Basic information') }}
            </div>
            <span>{{ s__('ComplianceFrameworks|Name, description') }}</span>
          </div>
        </div>
        <gl-collapse visible class="gl-p-4">
          <gl-form-group
            :label="$options.i18n.titleInputLabel"
            label-for="name-input"
            :invalid-feedback="$options.i18n.titleInputInvalid"
            :state="isValidName"
            data-testid="name-input-group"
          >
            <gl-form-input
              id="name-input"
              v-model="formData.name"
              name="name"
              :state="isValidName"
              data-testid="name-input"
            />
          </gl-form-group>

          <gl-form-group
            :label="$options.i18n.descriptionInputLabel"
            label-for="description-input"
            :invalid-feedback="$options.i18n.descriptionInputInvalid"
            :state="isValidDescription"
            data-testid="description-input-group"
          >
            <gl-form-input
              id="description-input"
              v-model="formData.description"
              name="description"
              :state="isValidDescription"
              data-testid="description-input"
            />
          </gl-form-group>
          <color-picker
            v-model="formData.color"
            :label="$options.i18n.colorInputLabel"
            :state="isValidColor"
          />
          <gl-form-group
            v-if="pipelineConfigurationFullPathEnabled && pipelineConfigurationEnabled"
            :label="$options.i18n.pipelineConfigurationInputLabel"
            label-for="pipeline-configuration-input"
            :invalid-feedback="pipelineConfigurationFeedbackMessage"
            :state="isValidPipelineConfiguration"
            data-testid="pipeline-configuration-input-group"
          >
            <template #description>
              <gl-sprintf :message="$options.i18n.pipelineConfigurationInputDescription">
                <template #code="{ content }">
                  <code>{{ content }}</code>
                </template>

                <template #link="{ content }">
                  <gl-link :href="compliancePipelineConfigurationHelpPath" target="_blank">{{
                    content
                  }}</gl-link>
                </template>
              </gl-sprintf>
            </template>

            <gl-form-input
              id="pipeline-configuration-input"
              v-model="formData.pipelineConfigurationFullPath"
              name="pipeline_configuration_full_path"
              :state="isValidPipelineConfiguration"
              data-testid="pipeline-configuration-input"
            />
          </gl-form-group>
          <template v-if="!pipelineConfigurationEnabled">
            <gl-form-group
              id="disabled-pipeline-configuration-input-group"
              :label="$options.i18n.pipelineConfigurationInputLabel"
              label-for="disabled-pipeline-configuration-input"
              data-testid="disabled-pipeline-configuration-input-group"
            >
              <div :id="$options.disabledPipelineConfigurationInputPopoverTarget" tabindex="0">
                <gl-form-input
                  id="disabled-pipeline-configuration-input"
                  disabled
                  data-testid="disabled-pipeline-configuration-input"
                />
              </div>
            </gl-form-group>
            <gl-popover
              :title="$options.i18n.pipelineConfigurationInputDisabledPopoverTitle"
              show-close-button
              :target="$options.disabledPipelineConfigurationInputPopoverTarget"
              data-testid="disabled-pipeline-configuration-input-popover"
            >
              <p class="gl-mb-0">
                <gl-sprintf
                  :message="$options.i18n.pipelineConfigurationInputDisabledPopoverContent"
                >
                  <template #link="{ content }">
                    <gl-link
                      :href="$options.i18n.pipelineConfigurationInputDisabledPopoverLink"
                      target="_blank"
                      class="gl-font-sm"
                    >
                      {{ content }}</gl-link
                    >
                  </template>
                </gl-sprintf>
              </p>
            </gl-popover>
          </template>
          <gl-form-checkbox v-model="formData.default" name="default">
            <span class="gl-font-weight-bold">{{
              s__('ComplianceFrameworks|Set as default')
            }}</span>
            <template #help>
              <div>
                {{
                  s__(
                    'ComplianceFrameworks|Default framework will be applied automatically to any new project created in the group or sub group.',
                  )
                }}
              </div>
              <div>
                {{ s__('ComplianceFrameworks|There can be only one default framework.') }}
              </div>
            </template>
          </gl-form-checkbox>
        </gl-collapse>
        <div class="gl-display-flex gl-pt-5 gl-gap-3">
          <gl-button
            type="submit"
            variant="confirm"
            class="js-no-auto-disable"
            data-testid="submit-btn"
            :disabled="disableSubmitBtn"
          >
            {{ saveButtonText }}
          </gl-button>
          <gl-button data-testid="cancel-btn" @click="onCancel">{{ __('Cancel') }}</gl-button>
        </div>
      </gl-form>
    </template>
  </div>
</template>

<script>
import {
  GlButton,
  GlCollapsibleListbox,
  GlDatepicker,
  GlDropdownDivider,
  GlLink,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlSprintf,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { getDateInFuture } from '~/lib/utils/datetime_utility';
import CiEnvironmentsDropdown from '~/ci/common/private/ci_environments_dropdown';
import { INDEX_ROUTE_NAME, ROTATION_PERIOD_OPTIONS } from '../../constants';
import { convertRotationPeriod } from '../../utils';
import SecretPreviewModal from './secret_preview_modal.vue';

export default {
  name: 'SecretForm',
  components: {
    CiEnvironmentsDropdown,
    GlButton,
    GlCollapsibleListbox,
    GlDropdownDivider,
    GlDatepicker,
    GlLink,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlSprintf,
    SecretPreviewModal,
  },
  props: {
    areEnvironmentsLoading: {
      type: Boolean,
      required: true,
    },
    environments: {
      type: Array,
      required: false,
      default: () => [],
    },
    isEditing: {
      type: Boolean,
      required: true,
    },
    redirectToRouteName: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      customRotationPeriod: '',
      isPreviewing: false,
      secret: {
        createdAt: undefined,
        environment: '*',
        expiration: null,
        description: '',
        key: '',
        rotationPeriod: '',
        value: '',
      },
    };
  },
  computed: {
    createdAt() {
      return this.secret.createdAt || Date.now();
    },
    minExpirationDate() {
      // secrets can expire tomorrow, but not today or yesterday
      const today = new Date();
      return getDateInFuture(today, 1);
    },
    rotationPeriodText() {
      return convertRotationPeriod(this.secret.rotationPeriod);
    },
    rotationPeriodToggleText() {
      if (this.secret.rotationPeriod.length) {
        return this.rotationPeriodText;
      }

      return s__('Secrets|Select a rotation interval');
    },
  },
  methods: {
    hidePreviewModal() {
      this.isPreviewing = false;
    },
    setCustomRotationPeriod() {
      this.secret.rotationPeriod = this.customRotationPeriod.trim();
    },
    setEnvironment(environment) {
      this.secret = { ...this.secret, environment };
    },
    showPreviewModal() {
      this.isPreviewing = true;
    },
    submitSecret() {
      // TODO: submit secret
    },
  },
  datePlaceholder: 'YYYY-MM-DD',
  cronPlaceholder: '0 6 * * *',
  secretsIndexRoute: INDEX_ROUTE_NAME,
  rotationPeriodOptions: ROTATION_PERIOD_OPTIONS,
};
</script>
<template>
  <div>
    <gl-form @submit.prevent="showPreviewModal">
      <gl-form-group :label="s__('Secrets|Secret key')" label-for="secret-key">
        <gl-form-input
          id="secret-key"
          v-model="secret.key"
          data-testid="secret-key"
          :placeholder="s__('Secrets|Enter a key name')"
        />
      </gl-form-group>
      <gl-form-group :label="s__('Secrets|Value')" label-for="secret-value">
        <gl-form-textarea
          id="secret-value"
          v-model="secret.value"
          data-testid="secret-value"
          rows="5"
          max-rows="15"
          :placeholder="s__('Secrets|Value for the key')"
          :spellcheck="false"
        />
      </gl-form-group>
      <gl-form-group :label="__('Description')" label-for="secret-description">
        <gl-form-input
          id="secret-description"
          v-model="secret.description"
          data-testid="secret-description"
          :placeholder="s__('Secrets|Add a description for the secret')"
        />
      </gl-form-group>
      <gl-form-group
        :label="s__('Secrets|Select environment')"
        label-for="secret-environment"
        class="gl-w-half"
      >
        <ci-environments-dropdown
          :are-environments-loading="areEnvironmentsLoading"
          :environments="environments"
          :selected-environment-scope="secret.environment"
          @search-environment-scope="$emit('search-environment', $event)"
        />
      </gl-form-group>
      <div class="gl-display-flex gl-gap-4">
        <gl-form-group
          class="gl-w-full"
          :label="s__('Secrets|Set expiration')"
          label-for="secret-expiration"
        >
          <gl-datepicker
            id="secret-expiration"
            v-model="secret.expiration"
            class="gl-max-w-none"
            :placeholder="$options.datePlaceholder"
            :min-date="minExpirationDate"
          />
        </gl-form-group>
        <gl-form-group
          class="gl-w-full"
          :label="s__('Secrets|Rotation period')"
          label-for="secret-rotation-period"
        >
          <gl-collapsible-listbox
            id="secret-rotation-period"
            v-model="secret.rotationPeriod"
            block
            :label-text="s__('Secrets|Rotation period')"
            :header-text="s__('Secrets|Intervals')"
            :toggle-text="rotationPeriodToggleText"
            :items="$options.rotationPeriodOptions"
          >
            <template #footer>
              <gl-dropdown-divider />
              <div class="gl-mt-3 gl-mb-4 gl-mx-3">
                <p class="gl-py-0 gl-my-0">{{ s__('Secrets|Add custom interval.') }}</p>
                <p class="gl-py-0 gl-my-0 gl-font-sm gl-text-secondary">
                  <gl-sprintf :message="__('Use CRON syntax. %{linkStart}Learn more.%{linkEnd}')">
                    <template #link="{ content }">
                      <gl-link href="https://crontab.guru/" target="_blank">{{ content }}</gl-link>
                    </template>
                  </gl-sprintf>
                </p>
                <gl-form-input
                  v-model="customRotationPeriod"
                  data-testid="secret-cron"
                  :placeholder="$options.cronPlaceholder"
                  class="gl-my-3"
                />
                <gl-button
                  class="gl-float-right"
                  data-testid="add-custom-rotation-button"
                  size="small"
                  variant="confirm"
                  @click="setCustomRotationPeriod"
                >
                  {{ __('Add interval') }}
                </gl-button>
              </div>
            </template>
          </gl-collapsible-listbox>
        </gl-form-group>
      </div>
      <!-- TODO: replace placeholder access permission fields with the real thing -->
      <gl-form-group label-for="secret-roles-and-users" :label="__('Access permission')">
        <div class="gl-display-flex gl-gap-4">
          <gl-form-input :placeholder="__('Select roles or users')" disabled />
          <gl-form-input :placeholder="__('Select permission')" disabled />
        </div>
      </gl-form-group>
      <div class="gl-my-3">
        <gl-button variant="confirm" data-testid="submit-form-button" @click="showPreviewModal">
          {{ __('Continue') }}
        </gl-button>
        <gl-button
          :to="{ name: $options.secretsIndexRoute }"
          data-testid="cancel-button"
          class="gl-my-4"
        >
          {{ __('Cancel') }}
        </gl-button>
      </div>
    </gl-form>
    <secret-preview-modal
      :created-at="createdAt"
      :description="secret.description"
      :expiration="secret.expiration"
      :is-editing="isEditing"
      :is-visible="isPreviewing"
      :secret-key="secret.key"
      :rotation-period="rotationPeriodText"
      @hide-preview-modal="hidePreviewModal"
      @submit-secret="submitSecret"
      v-on="$listeners"
    />
  </div>
</template>

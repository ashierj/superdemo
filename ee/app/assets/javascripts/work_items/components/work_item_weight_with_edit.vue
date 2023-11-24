<script>
import { GlButton, GlForm, GlFormInput, GlTooltipDirective } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import Tracking from '~/tracking';
import {
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_UPDATING,
  TRACKING_CATEGORY_SHOW,
} from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';

export default {
  inputId: 'weight-widget-input',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    GlForm,
    GlFormInput,
  },
  mixins: [Tracking.mixin()],
  inject: ['hasIssueWeightsFeature'],
  props: {
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    weight: {
      type: Number,
      required: false,
      default: null,
    },
    workItemId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isEditing: false,
      clickingClearButton: false,
      workItem: {},
    };
  },
  computed: {
    hasWeight() {
      return this.weight !== null;
    },
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_weight',
        property: `type_${this.workItemType}`,
      };
    },
  },
  methods: {
    blurInput() {
      this.$refs.input.$el.blur();
    },
    handleFocus() {
      this.isEditing = true;
    },
    updateWeightFromInput(event) {
      if (event.target.value === '') {
        this.updateWeight(null);
        return;
      }

      const weight = Number(event.target.value);
      this.updateWeight(weight);
    },
    updateWeight(weight) {
      if (this.clickingClearButton) return;
      if (!this.canUpdate) return;
      this.isEditing = false;

      if (this.weight === weight) return;

      this.track('updated_weight');
      this.$apollo
        .mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              weightWidget: {
                weight,
              },
            },
          },
        })
        .then(({ data }) => {
          if (data.workItemUpdate.errors.length) {
            throw new Error(data.workItemUpdate.errors.join('\n'));
          }
        })
        .catch((error) => {
          const msg = sprintfWorkItem(I18N_WORK_ITEM_ERROR_UPDATING, this.workItemType);
          this.$emit('error', msg);
          Sentry.captureException(error);
        });
    },
  },
};
</script>

<template>
  <div v-if="hasIssueWeightsFeature">
    <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
      <!-- hide header when editing, since we then have a form label. Keep it reachable for screenreader nav  -->
      <h3 :class="{ 'gl-sr-only': isEditing }" class="gl-mb-0! gl-heading-scale-5">
        {{ __('Weight') }}
      </h3>
      <gl-button
        v-if="canUpdate && !isEditing"
        data-testid="edit-weight"
        category="tertiary"
        size="small"
        @click="isEditing = true"
        >{{ __('Edit') }}</gl-button
      >
    </div>
    <gl-form v-if="isEditing" @submit.prevent="blurInput">
      <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
        <label :for="$options.inputId" class="gl-mb-0">{{ __('Weight') }}</label>
        <gl-button
          data-testid="apply-weight"
          category="tertiary"
          size="small"
          @click="isEditing = false"
          >{{ __('Apply') }}</gl-button
        >
      </div>
      <!-- wrapper for the form input so the borders fit inside the sidebar -->
      <div class="gl-px-2 gl-relative">
        <gl-form-input
          :id="$options.inputId"
          ref="input"
          min="0"
          class="hide-unfocused-input-decoration gl-display-block"
          type="number"
          :placeholder="__('Enter a number')"
          :value="weight"
          autofocus
          @blur="updateWeightFromInput"
          @focus="handleFocus"
          @keydown.exact.esc.stop="blurInput"
        />
        <gl-button
          v-if="hasWeight"
          v-gl-tooltip
          data-testid="remove-weight"
          variant="default"
          category="tertiary"
          size="small"
          name="clear"
          icon="clear"
          class="gl-clear-icon-button gl-absolute gl-top-2 gl-right-7"
          :title="__('Remove weight')"
          :aria-label="__('Remove weight')"
          @mousedown="clickingClearButton = true"
          @mouseup="clickingClearButton = false"
          @click="updateWeight(null)"
        />
      </div>
    </gl-form>
    <template v-else-if="hasWeight">
      <div>{{ weight }}</div>
    </template>
    <template v-else>
      <div class="gl-text-secondary">{{ __('None') }}</div>
    </template>
  </div>
</template>

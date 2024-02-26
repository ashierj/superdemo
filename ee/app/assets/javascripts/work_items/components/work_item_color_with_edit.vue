<script>
import {
  GlForm,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlButton,
  GlLoadingIcon,
} from '@gitlab/ui';
import { validateHexColor } from '~/lib/utils/color_utils';
import { __ } from '~/locale';
import {
  I18N_WORK_ITEM_ERROR_UPDATING,
  sprintfWorkItem,
  WIDGET_TYPE_COLOR,
  TRACKING_CATEGORY_SHOW,
} from '~/work_items/constants';
import { DEFAULT_COLOR } from '~/vue_shared/components/color_select_dropdown/constants';
import SidebarColorView from '~/sidebar/components/sidebar_color_view.vue';
import SidebarColorPicker from '~/sidebar/components/sidebar_color_picker.vue';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import Tracking from '~/tracking';

export default {
  i18n: {
    colorLabel: __('Color'),
  },
  inputId: 'color-widget-input',
  components: {
    GlForm,
    SidebarColorPicker,
    SidebarColorView,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlButton,
    GlLoadingIcon,
  },
  mixins: [Tracking.mixin()],
  props: {
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItem: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      currentColor: '',
      isEditing: false,
      isUpdating: false,
    };
  },
  computed: {
    workItemId() {
      return this.workItem?.id;
    },
    workItemType() {
      return this.workItem?.workItemType?.name;
    },
    workItemColorWidget() {
      return this.workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_COLOR);
    },
    color() {
      return this.workItemColorWidget?.color;
    },
    textColor() {
      return this.workItemColorWidget?.textColor;
    },
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_color',
        property: `type_${this.workItemType}`,
      };
    },
  },
  created() {
    this.currentColor = this.color;
  },
  methods: {
    async updateColor() {
      if (!this.canUpdate || this.color === this.currentColor) {
        this.isEditing = false;
        return;
      }

      this.isUpdating = true;
      this.currentColor = validateHexColor(this.currentColor)
        ? this.currentColor
        : DEFAULT_COLOR.color;

      try {
        const {
          data: {
            workItemUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              colorWidget: { color: this.currentColor },
            },
          },
          optimisticResponse: {
            workItemUpdate: {
              errors: [],
              workItem: {
                ...this.workItem,
                widgets: [
                  ...this.workItem.widgets,
                  {
                    color: this.currentColor,
                    textColor: this.textColor,
                    type: WIDGET_TYPE_COLOR,
                    __typename: 'WorkItemWidgetColor',
                  },
                ],
              },
            },
          },
        });

        if (errors.length) {
          throw new Error(errors.join('\n'));
        }
        this.track('updated_color');
      } catch {
        const msg = sprintfWorkItem(I18N_WORK_ITEM_ERROR_UPDATING, this.workItemType);
        this.$emit('error', msg);
      } finally {
        this.isEditing = false;
        this.isUpdating = false;
      }
    },
    resetColor() {
      this.currentColor = null;
      this.updateColor();
    },
  },
};
</script>

<template>
  <div class="work-item-color-with-edit">
    <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
      <h3 :class="{ 'gl-sr-only': isEditing }" class="gl-mb-0! gl-heading-5">
        {{ $options.i18n.colorLabel }}
      </h3>
      <gl-button
        v-if="canUpdate && !isEditing"
        data-testid="edit-color"
        category="tertiary"
        size="small"
        @click="isEditing = true"
        >{{ __('Edit') }}</gl-button
      >
    </div>
    <gl-form v-if="isEditing" class="work-item-dropdown">
      <div class="gl-display-flex gl-align-items-center">
        <label :for="$options.inputId" class="gl-mb-0">{{ $options.i18n.colorLabel }}</label>
        <gl-loading-icon v-if="isUpdating" size="sm" inline class="gl-ml-3" />
        <gl-button
          data-testid="apply-color"
          category="tertiary"
          size="small"
          class="gl-ml-auto"
          :disabled="isUpdating"
          @click="updateColor"
          >{{ __('Apply') }}</gl-button
        >
      </div>
      <gl-disclosure-dropdown
        :id="$options.inputId"
        category="tertiary"
        :auto-close="false"
        start-opened
        @hidden="updateColor"
      >
        <template #header>
          <div
            class="gl-display-flex gl-align-items-center gl-p-4! gl-min-h-8 gl-border-b-1 gl-border-b-solid gl-border-b-gray-200"
          >
            <div
              data-testid="color-header-title"
              class="gl-flex-grow-1 gl-font-weight-bold gl-font-sm gl-pr-2"
            >
              {{ __('Select a color') }}
            </div>
            <gl-button
              data-testid="reset-color"
              category="tertiary"
              size="small"
              class="gl-font-sm!"
              @click="resetColor"
              >{{ __('Reset') }}</gl-button
            >
          </div>
        </template>
        <template #toggle>
          <sidebar-color-view :color="color" />
        </template>
        <gl-disclosure-dropdown-item>
          <sidebar-color-picker v-model="currentColor" :autofocus="true" class="gl-px-2" />
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown>
    </gl-form>
    <div v-else class="work-item-field-value">
      <sidebar-color-view :color="currentColor" />
    </div>
  </div>
</template>

<script>
import { GlFormGroup, GlDisclosureDropdown, GlDisclosureDropdownItem, GlButton } from '@gitlab/ui';
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
  components: {
    GlFormGroup,
    SidebarColorPicker,
    SidebarColorView,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlButton,
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
    };
  },
  computed: {
    workItemId() {
      return this.workItem.id;
    },
    workItemType() {
      return this.workItem.workItemType.name;
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
      if (!this.canUpdate) {
        return;
      }

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
          variables: {
            input: {
              id: this.workItemId,
              colorWidget: { color: this.currentColor },
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
      }
    },
  },
};
</script>

<template>
  <gl-form-group
    class="work-item-dropdown"
    :label="$options.i18n.colorLabel"
    label-class="gl-pb-0! gl-mt-3 gl-overflow-wrap-break gl-display-flex gl-align-items-center work-item-field-label gl-w-full"
    label-cols="3"
    label-cols-lg="2"
  >
    <div v-if="!canUpdate" class="gl-ml-4 gl-mt-3 work-item-field-value">
      <sidebar-color-view :color="currentColor" />
    </div>
    <gl-disclosure-dropdown v-else category="tertiary" :auto-close="false" @hidden="updateColor">
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
        </div>
      </template>
      <template #toggle>
        <gl-button category="tertiary" class="work-item-color-button gl-display-flex">
          <sidebar-color-view :color="currentColor" />
        </gl-button>
      </template>
      <gl-disclosure-dropdown-item>
        <sidebar-color-picker v-model="currentColor" class="gl-px-2" />
      </gl-disclosure-dropdown-item>
    </gl-disclosure-dropdown>
  </gl-form-group>
</template>

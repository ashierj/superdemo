<script>
import { GlButton, GlSprintf } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';

const ITEMS_MAX_LIST = 5;

export default {
  name: 'ToggleList',
  components: {
    GlButton,
    GlSprintf,
  },
  props: {
    items: {
      type: Array,
      required: true,
      validator: (items) => items.length && items.every((item) => typeof item === 'string'),
    },
    bulletStyle: {
      type: Boolean,
      required: false,
      default: false,
    },
    customButtonText: {
      type: String,
      required: false,
      default: '',
    },
    customCloseButtonText: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      visibleItemIndex: ITEMS_MAX_LIST,
    };
  },
  computed: {
    buttonText() {
      if (this.isInitialState) {
        const itemsLength = this.items.length - ITEMS_MAX_LIST;

        if (this.customButtonText) return this.customButtonText;

        return sprintf(__('+ %{itemsLength} more'), {
          itemsLength,
        });
      }

      return this.customCloseButtonText || s__('SecurityOrchestration|Hide extra items');
    },
    isInitialState() {
      return this.visibleItemIndex === ITEMS_MAX_LIST;
    },
    initialList() {
      return this.items.slice(0, this.visibleItemIndex);
    },
    showButton() {
      return this.items.length > ITEMS_MAX_LIST;
    },
  },
  methods: {
    toggleItemsLength() {
      this.visibleItemIndex = this.isInitialState ? this.items.length : ITEMS_MAX_LIST;
    },
  },
};
</script>

<template>
  <div>
    <ul data-testid="items-list" class="gl-m-0" :class="{ 'gl-list-style-none': !bulletStyle }">
      <li
        v-for="(item, itemIdx) in initialList"
        :key="itemIdx"
        data-testid="list-item"
        class="gl-mt-2 gl-text"
      >
        <gl-sprintf :message="item">
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
      </li>
    </ul>
    <gl-button
      v-if="showButton"
      class="gl-ml-6 gl-mt-2"
      category="tertiary"
      variant="link"
      @click="toggleItemsLength"
    >
      {{ buttonText }}
    </gl-button>
  </div>
</template>

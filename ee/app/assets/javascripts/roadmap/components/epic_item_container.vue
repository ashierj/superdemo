<script>
import { generateKey } from '../utils/epic_utils';

export default {
  name: 'EpicItemContainer',
  components: {
    EpicItem: () => import('./epic_item.vue'),
  },
  props: {
    presetType: {
      type: String,
      required: true,
    },
    timeframe: {
      type: Array,
      required: true,
    },
    clientWidth: {
      type: Number,
      required: false,
      default: 0,
    },
    children: {
      type: Array,
      required: true,
    },
    childLevel: {
      type: Number,
      required: true,
    },
  },
  methods: {
    generateKey,
  },
};
</script>

<template>
  <div class="epic-list-item-container">
    <epic-item
      v-for="child in children"
      :key="generateKey(child)"
      :preset-type="presetType"
      :epic="child"
      :timeframe="timeframe"
      :client-width="clientWidth"
      :child-level="childLevel"
    />
  </div>
</template>

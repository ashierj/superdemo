<script>
export default {
  props: {
    parentItem: {
      type: Object,
      required: true,
    },
    children: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
};
</script>

<template>
  <div class="gl-new-card-body gl-py-0" data-testid="related-items-tree">
    <tree-root :parent-item="parentItem" :children="children" />
  </div>
</template>

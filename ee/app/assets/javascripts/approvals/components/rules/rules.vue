<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { TABLE_HEADERS } from '../../constants';

export default {
  props: {
    rules: {
      type: Array,
      required: true,
    },
  },
  TABLE_HEADERS,
};
</script>

<template>
  <table class="table b-table gl-table b-table-stacked-md gl-m-0">
    <thead class="text-nowrap">
      <slot name="thead" v-bind="$options.TABLE_HEADERS"></slot>
    </thead>
    <tbody>
      <slot name="tbody" :rules="rules" v-bind="$options.TABLE_HEADERS"></slot>
    </tbody>
  </table>
</template>

<script>
export default {
  name: 'GroupSecretsApp',
  props: {
    groupPath: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    queryVariables() {
      return {
        fullPath: this.groupPath,
        isGroup: true,
      };
    },
  },
};
</script>
<template>
  <router-view ref="router-view" :parent-query-variables="queryVariables" />
</template>

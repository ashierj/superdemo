<script>
export default {
  name: 'ProjectSecretsApp',
  props: {
    projectPath: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    queryVariables() {
      return {
        fullPath: this.projectPath,
        isProject: true,
      };
    },
  },
};
</script>
<template>
  <router-view ref="router-view" :parent-query-variables="queryVariables" />
</template>

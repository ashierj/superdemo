<script>
import { mockProjectSecretsData } from '../constants';

export default {
  name: 'ProjectSecretsApp',
  props: {
    projectPath: {
      type: String,
      required: false,
      default: undefined,
    },
    projectId: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  data() {
    return { projectSecrets: mockProjectSecretsData };
  },
};
</script>
<template>
  <router-view ref="router-view" :secrets="projectSecrets" />
</template>

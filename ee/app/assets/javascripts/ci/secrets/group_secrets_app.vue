<script>
import { mockGroupSecretsData } from './constants';

export default {
  name: 'GroupSecretsApp',
  props: {
    groupPath: {
      type: String,
      required: false,
      default: undefined,
    },
    groupId: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  data() {
    return { groupSecrets: mockGroupSecretsData };
  },
};
</script>
<template>
  <router-view ref="router-view" :secrets="groupSecrets" />
</template>

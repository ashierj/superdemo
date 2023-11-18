<script>
import getGroupSecretsQuery from '../graphql/queries/client/get_group_secrets.query.graphql';

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
  apollo: {
    secrets: {
      query: getGroupSecretsQuery,
      variables() {
        return {
          fullPath: this.groupPath,
        };
      },
      update(data) {
        return data.group.secrets.nodes || [];
      },
    },
  },
};
</script>
<template>
  <router-view ref="router-view" :secrets="secrets" />
</template>

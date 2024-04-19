<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';

export default {
  name: 'PromotionRequestsTabApp',
  props: {
    namespace: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState({
      data(state) {
        return state[this.namespace].data;
      },
    }),
  },
};
</script>
<template>
  <div>
    <ul>
      <li v-for="request in data" :key="request.id">
        {{ request.user.name }}
      </li>
    </ul>
  </div>
</template>

<script>
import SectionLayout from '../../section_layout.vue';
import { BOT_COMMENT_TYPE } from '../lib';

export default {
  name: 'BotCommentAction',
  components: {
    SectionLayout,
  },
  BOT_COMMENT_TYPE,
};
</script>

<template>
  <section-layout @remove="$emit('remove')">
    <template #content>{{ $options.BOT_COMMENT_TYPE }}</template>
  </section-layout>
</template>

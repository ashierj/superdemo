<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import SectionLayout from '../../section_layout.vue';

export default {
  i18n: {
    text: s__(
      'SecurityOrchestration|%{boldStart}Send a bot message%{boldEnd} as comment to merge request creator.',
    ),
  },
  name: 'BotCommentAction',
  components: {
    GlSprintf,
    SectionLayout,
  },
};
</script>

<template>
  <section-layout @remove="$emit('remove')">
    <template #content>
      <gl-sprintf :message="$options.i18n.text">
        <template #bold="{ content }">
          <b>{{ content }}</b>
        </template>
      </gl-sprintf>
    </template>
  </section-layout>
</template>

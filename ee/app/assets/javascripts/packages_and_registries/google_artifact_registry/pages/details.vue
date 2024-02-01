<script>
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

export default {
  name: 'ArtifactRegistryDetailsPage',
  components: {
    TitleArea,
  },
  inject: ['breadCrumbState'],
  computed: {
    imageParams() {
      return this.$route.params.image;
    },
    shortDigest() {
      // remove sha256: from the string, and show only the first 12 char
      return this.imageParams.split('sha256:')[1]?.substring(0, 12) ?? '';
    },
    imageNameAndShortDigest() {
      const [name] = this.imageParams.split('@');
      return `${name}@${this.shortDigest}`;
    },
  },
  mounted() {
    this.breadCrumbState.updateName(this.imageNameAndShortDigest);
  },
};
</script>

<template>
  <title-area :title="imageNameAndShortDigest" />
</template>

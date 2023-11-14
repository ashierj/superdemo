<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState } from 'vuex';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import LanguageFilter from './language_filter/index.vue';
import ArchivedFilter from './archived_filter/index.vue';
import FiltersTemplate from './filters_template.vue';

export default {
  name: 'BlobsFilters',
  components: {
    LanguageFilter,
    FiltersTemplate,
    ArchivedFilter,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapGetters(['currentScope']),
    ...mapState(['searchType']),
  },
};
</script>

<template>
  <filters-template>
    <language-filter class="gl-mb-5" />
    <archived-filter class="gl-mb-5" />
  </filters-template>
</template>

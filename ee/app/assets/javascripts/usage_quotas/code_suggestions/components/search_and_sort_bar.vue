<script>
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import {
  FILTERED_SEARCH_TERM,
  TOKEN_TITLE_PROJECT,
  TOKEN_TYPE_PROJECT,
  OPERATORS_IS,
} from '~/vue_shared/components/filtered_search_bar/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ProjectToken from 'ee/usage_quotas/code_suggestions/tokens/project_token.vue';

export default {
  name: 'SearchAndSortBar',
  components: {
    FilteredSearchBar,
  },
  mixins: [glFeatureFlagMixin()],
  inject: { fullPath: { default: '' } },
  data() {
    return {
      search: undefined,
    };
  },
  computed: {
    isFilteringEnabled() {
      return this.glFeatures.enableAddOnUsersFiltering;
    },
    tokens() {
      if (!this.isFilteringEnabled) return [];

      return [
        {
          fullPath: this.fullPath,
          icon: 'project',
          operators: OPERATORS_IS,
          title: TOKEN_TITLE_PROJECT,
          token: ProjectToken,
          type: TOKEN_TYPE_PROJECT,
          unique: true,
        },
      ];
    },
  },
  methods: {
    handleFilter(filterOptions) {
      this.$emit('onFilter', this.getFilterParams(filterOptions));
    },
    getFilterParams(filters = []) {
      return filters.reduce((filterParams, filter) => {
        const { type, value } = filter || {};
        if (!value?.data) return filterParams;
        switch (type) {
          case TOKEN_TYPE_PROJECT:
            return { ...filterParams, filterByProjectId: value.data };
          case FILTERED_SEARCH_TERM:
            return { ...filterParams, search: value.data };
          default:
            return filterParams;
        }
      }, {});
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-bg-gray-10 gl-p-3 gl-gap-3">
    <filtered-search-bar
      class="gl-flex-grow-1"
      :namespace="fullPath"
      :tokens="tokens"
      :search-input-placeholder="__('Filter users')"
      @onFilter="handleFilter"
    />
  </div>
</template>

<script>
import { __ } from '~/locale';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import {
  FILTERED_SEARCH_TERM,
  TOKEN_TITLE_PROJECT,
  TOKEN_TYPE_PROJECT,
  OPERATORS_IS,
  TOKEN_TITLE_GROUP_INVITE,
  TOKEN_TYPE_GROUP_INVITE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import ProjectToken from 'ee/usage_quotas/code_suggestions/tokens/project_token.vue';
import { processFilters } from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';

export default {
  name: 'SearchAndSortBar',
  components: {
    FilteredSearchBar,
  },
  mixins: [glFeatureFlagMixin()],
  inject: { fullPath: { default: '' } },
  props: {
    sortOptions: {
      type: Array,
      default: () => [],
      required: false,
    },
  },
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
        {
          options: [
            { value: 'true', title: __('Yes') },
            { value: 'false', title: __('No') },
          ],
          icon: 'user',
          operators: OPERATORS_IS,
          title: TOKEN_TITLE_GROUP_INVITE,
          token: BaseToken,
          type: TOKEN_TYPE_GROUP_INVITE,
          unique: true,
        },
      ];
    },
  },
  methods: {
    handleFilter(filterOptions) {
      const {
        [FILTERED_SEARCH_TERM]: searchFilters = [],
        [TOKEN_TYPE_PROJECT]: [{ value: filterByProjectId } = {}] = [],
        [TOKEN_TYPE_GROUP_INVITE]: [{ value: filterByGroupInvite } = {}] = [],
      } = processFilters(filterOptions);
      const search = this.processSearchFilters(searchFilters);
      this.$emit('onFilter', { search, filterByProjectId, filterByGroupInvite });
    },
    handleSort(sortValue) {
      this.$emit('onSort', sortValue);
    },
    processSearchFilters(searchFilters) {
      if (searchFilters.length === 0) return undefined;
      return searchFilters.reduce((acc, { value }) => {
        if (!acc && !value) return undefined;
        if (!value) return acc;
        return `${acc} ${value}`.trim();
      }, '');
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
      :sort-options="sortOptions"
      @onFilter="handleFilter"
      @onSort="handleSort"
    />
  </div>
</template>

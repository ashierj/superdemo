<script>
import { GlFilteredSearch } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import LicenseToken from './tokens/license_token.vue';
import ProjectToken from './tokens/project_token.vue';

export default {
  components: {
    GlFilteredSearch,
  },
  data() {
    return {
      value: [],
      currentFilterParams: null,
    };
  },
  computed: {
    ...mapState(['currentList']),
    tokens() {
      return [
        {
          type: 'licenses',
          title: __('License'),
          multiSelect: true,
          unique: true,
          token: LicenseToken,
          operators: OPERATORS_IS,
        },
        {
          type: 'project_ids',
          title: __('Project'),
          multiSelect: true,
          unique: true,
          token: ProjectToken,
          operators: OPERATORS_IS,
        },
      ];
    },
  },
  methods: {
    ...mapActions('allDependencies', ['setSearchFilterParameters', 'fetchDependencies']),
  },
};
</script>

<template>
  <gl-filtered-search
    :placeholder="__('Search or filter dependencies...')"
    :available-tokens="tokens"
    terms-as-tokens
    @input="setSearchFilterParameters"
    @submit="fetchDependencies({ page: 1 })"
  />
</template>

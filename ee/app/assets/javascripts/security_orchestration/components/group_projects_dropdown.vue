<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import produce from 'immer';
import { n__, __ } from '~/locale';
import getGroupProjects from 'ee/security_orchestration/graphql/queries/get_group_projects.query.graphql';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

export default {
  i18n: {
    projectDropdownHeader: __('Select projects'),
    selectAllLabel: __('Select all'),
    clearAllLabel: __('Clear all'),
  },
  name: 'GroupProjectsDropdown',
  components: {
    GlCollapsibleListbox,
  },
  apollo: {
    projects: {
      query: getGroupProjects,
      variables() {
        return {
          fullPath: this.groupFullPath,
          search: this.searchTerm,
        };
      },
      update(data) {
        return data.group?.projects?.nodes || [];
      },
      result({ data }) {
        this.projectsPageInfo = data?.group?.projects?.pageInfo || {};
      },
      error() {
        this.$emit('projects-query-error');
      },
    },
  },
  props: {
    groupFullPath: {
      type: String,
      required: true,
    },
    placement: {
      type: String,
      required: false,
      default: 'left',
    },
    selectedProjectsIds: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      projectsPageInfo: {},
      searchTerm: '',
      projects: [],
    };
  },
  computed: {
    dropdownPlaceholder() {
      if (this.selectedProjectsIds.length === this.projects.length && !this.loading) {
        return __('All projects selected');
      }
      if (this.selectedProjectsIds.length) {
        return n__('%d project selected', '%d projects selected', this.selectedProjectsIds.length);
      }
      return __('Select projects');
    },
    loading() {
      return this.$apollo.queries.projects.loading;
    },
    projectListBoxItems() {
      return this.projects.map(({ id, name }) => ({ text: name, value: id }));
    },
    projectsIds() {
      return this.projects.map(({ id }) => id);
    },
  },
  created() {
    this.debouncedSearch = debounce(this.setSearchTerm, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  destroyed() {
    this.debouncedSearch.cancel();
  },
  methods: {
    async fetchMoreGroupProjects() {
      this.$apollo.queries.projects
        .fetchMore({
          variables: {
            fullPath: this.groupFullPath,
            after: this.projectsPageInfo.endCursor,
          },
          updateQuery(previousResult, { fetchMoreResult }) {
            return produce(fetchMoreResult, (draftData) => {
              draftData.group.projects.nodes = [
                ...previousResult.group.projects.nodes,
                ...draftData.group.projects.nodes,
              ];
            });
          },
        })
        .catch(() => {
          this.$emit('projects-query-error');
        });
    },
    setSearchTerm(searchTerm = '') {
      this.searchTerm = searchTerm.trim();
    },
    selectProjects(ids) {
      this.$emit('select', ids);
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    block
    is-check-centered
    multiple
    searchable
    fluid-width
    :loading="loading"
    :header-text="$options.i18n.projectDropdownHeader"
    :infinite-scroll="projectsPageInfo.hasNextPage"
    :infinite-scroll-loading="loading"
    :searching="loading"
    :selected="selectedProjectsIds"
    :placement="placement"
    :items="projectListBoxItems"
    :reset-button-label="$options.i18n.clearAllLabel"
    :show-select-all-button-label="$options.i18n.selectAllLabel"
    :toggle-text="dropdownPlaceholder"
    @bottom-reached="fetchMoreGroupProjects"
    @reset="selectProjects([])"
    @search="debouncedSearch"
    @select="selectProjects"
    @select-all="selectProjects(projectsIds)"
  />
</template>

<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import produce from 'immer';
import { __ } from '~/locale';
import { renderMultiSelectText } from 'ee/security_orchestration/components/policy_editor/utils';
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
    selected: {
      type: [Array, String],
      required: false,
      default: () => [],
    },
    multiple: {
      type: Boolean,
      required: false,
      default: true,
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
    formattedSelectedProjectsIds() {
      return this.multiple ? this.selected : [this.selected];
    },
    existingFormattedSelectedProjectsIds() {
      if (this.multiple) {
        return this.selected.filter((id) => this.projectsIds.includes(id));
      }

      return this.selected;
    },
    dropdownPlaceholder() {
      return renderMultiSelectText(
        this.formattedSelectedProjectsIds,
        this.projectItems,
        __('projects'),
      );
    },
    loading() {
      return this.$apollo.queries.projects.loading;
    },
    projectItems() {
      return this.projects?.reduce((acc, { id, name }) => {
        acc[id] = name;
        return acc;
      }, {});
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
    selectProjects(selected) {
      const ids = this.multiple ? selected : [selected];
      const selectedProjects = this.projects.filter(({ id }) => ids.includes(id));
      const payload = this.multiple ? selectedProjects : selectedProjects[0];
      this.$emit('select', payload);
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    block
    is-check-centered
    searchable
    fluid-width
    :multiple="multiple"
    :loading="loading"
    :header-text="$options.i18n.projectDropdownHeader"
    :infinite-scroll="projectsPageInfo.hasNextPage"
    :infinite-scroll-loading="loading"
    :searching="loading"
    :selected="existingFormattedSelectedProjectsIds"
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

<script>
import produce from 'immer';
import { GlLoadingIcon } from '@gitlab/ui';
import { s__, n__, sprintf, __ } from '~/locale';
import getGroupProjects from 'ee/security_orchestration/graphql/queries/get_group_projects.query.graphql';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { mapShortIdsToFullGraphQlFormat } from 'ee/security_orchestration/components/policy_drawer/utils';
import ToggleList from './toggle_list.vue';

export default {
  name: 'ProjectsToggleList',
  components: {
    GlLoadingIcon,
    ToggleList,
  },
  i18n: {
    allProjectsText: s__(
      'SecurityOrchestration|%{allLabel} %{projectCount} %{projectLabel} in this group',
    ),
    allProjectsExceptText: s__('SecurityOrchestration|All projects in this group except:'),
    allProjectsButtonText: s__('SecurityOrchestration|Show all included projects'),
    hideProjectsButtonText: s__('SecurityOrchestration|Hide extra projects'),
    includingProjectsText: s__('SecurityOrchestration|Following projects:'),
    showMoreProjectsLabel: s__('SecurityOrchestration|Show more projects'),
    hideMoreProjectsLabel: s__('SecurityOrchestration|Hide extra projects'),
    allLabel: __('All'),
    projectsLabel: __('projects'),
  },
  apollo: {
    projects: {
      query: getGroupProjects,
      variables() {
        return {
          fullPath: this.namespacePath,
          projectIds: mapShortIdsToFullGraphQlFormat(TYPENAME_PROJECT, this.projectIds),
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
  inject: ['namespacePath'],
  props: {
    projectIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    including: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      page: 1,
      projects: [],
      projectsPageInfo: {},
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.projects?.loading;
    },
    allProjects() {
      return !this.including && this.projectIds.length === 0;
    },
    allProjectsExcept() {
      return !this.including && this.projectIds.length > 0;
    },
    customButtonText() {
      return this.allProjects ? this.$options.i18n.allProjectsButtonText : null;
    },
    header() {
      if (this.allProjects) {
        return this.renderHeader(this.$options.i18n.allProjectsText);
      }

      if (this.allProjectsExcept) {
        return this.$options.i18n.allProjectsExceptText;
      }

      return this.$options.i18n.includingProjectsText;
    },
    projectNames() {
      return this.projects.map(({ name }) => name);
    },
  },
  methods: {
    fetchNextPage() {
      if (this.projectsPageInfo.hasNextPage) {
        this.$apollo.queries.projects
          .fetchMore({
            variables: {
              after: this.projectsPageInfo.endCursor,
            },
            updateQuery: (previousResult, { fetchMoreResult }) => {
              this.page += 1;
              return produce(fetchMoreResult, (draftData) => {
                draftData.group.projects.nodes = [
                  ...previousResult.group.projects.nodes,
                  ...draftData.group.projects.nodes,
                ];
              });
            },
          })
          .catch(() => this.$emit('projects-fetch-more-query-error'));
      }
    },
    renderHeader(message) {
      const projectLength = this.projects.length;
      const projectLabel = n__('project', 'projects', projectLength);

      return sprintf(message, {
        allLabel: projectLength > 1 ? this.$options.i18n.allLabel : '',
        projectCount: projectLength,
        projectLabel,
      }).trim();
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="loading" />

    <template v-else>
      <p class="gl-mb-3" data-testid="toggle-list-header">{{ header }}</p>

      <toggle-list
        v-if="projects.length"
        bullet-style
        :custom-button-text="$options.i18n.showMoreProjectsLabel"
        :custom-close-button-text="$options.i18n.hideMoreProjectsLabel"
        :has-next-page="projectsPageInfo.hasNextPage"
        :default-button-text="customButtonText"
        :default-close-button-text="$options.i18n.hideProjectsButtonText"
        :items="projectNames"
        :page="page"
        @load-next-page="fetchNextPage"
      />
    </template>
  </div>
</template>

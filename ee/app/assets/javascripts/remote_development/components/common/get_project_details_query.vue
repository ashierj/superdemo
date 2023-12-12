<script>
import { uniqBy } from 'lodash';
import { logError } from '~/lib/logger';
import getProjectDetailsQuery from '../../graphql/queries/get_project_details.query.graphql';
import getGroupClusterAgentsQuery from '../../graphql/queries/get_group_cluster_agents.query.graphql';
import { DEFAULT_DEVFILE_PATH } from '../../constants';

export default {
  props: {
    projectFullPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  apollo: {
    projectDetails: {
      query: getProjectDetailsQuery,
      variables() {
        return {
          projectFullPath: this.projectFullPath,
          devFilePath: DEFAULT_DEVFILE_PATH,
        };
      },
      skip() {
        return !this.projectFullPath;
      },
      update() {
        return [];
      },
      error(error) {
        logError(error);
      },
      async result(result) {
        if (result.error || !result.data.project) {
          this.$emit('error');
          return;
        }

        const { nameWithNamespace, repository, group, id } = result.data.project;

        const hasDevFile = repository
          ? repository.blobs.nodes.some(({ path }) => path === DEFAULT_DEVFILE_PATH)
          : false;
        const rootRef = repository ? repository.rootRef : null;

        if (!group) {
          // Guard clause: do not attempt to find agents if project does not have a group
          this.$emit('result', {
            id,
            fullPath: this.projectFullPath,
            nameWithNamespace,
            clusterAgents: [],
            hasDevFile,
            rootRef,
          });
          return;
        }

        const groupFullPath = group.fullPath;
        const groupFullPathParts = groupFullPath.split('/') || [];
        const groupPathsFromRoot = groupFullPathParts.map((_, i, arr) =>
          arr.slice(0, i + 1).join('/'),
        );
        const clusterAgentsResponses = await Promise.all(
          groupPathsFromRoot.map(this.fetchClusterAgents),
        );

        const errors = clusterAgentsResponses.filter((response) => response.error);
        if (errors.length > 0) {
          errors.forEach((error) => logError(error.error));
          this.$emit('error');
          return;
        }

        const clusterAgents = clusterAgentsResponses.flatMap((response) => response.result);
        const uniqClusterAgents = uniqBy(clusterAgents, 'value');

        this.$emit('result', {
          id,
          fullPath: this.projectFullPath,
          nameWithNamespace,
          clusterAgents: uniqClusterAgents,
          hasDevFile,
          rootRef,
        });
      },
    },
  },
  methods: {
    async fetchClusterAgents(groupPath) {
      try {
        const { data, error } = await this.$apollo.query({
          query: getGroupClusterAgentsQuery,
          variables: { groupPath },
        });

        if (error) {
          return { error };
        }

        return {
          result:
            data.group?.clusterAgents?.nodes.map(({ id, name, project }) => ({
              value: id,
              text: `${project.nameWithNamespace} / ${name}`,
            })) || [],
        };
      } catch (error) {
        return { error };
      }
    },
  },
  render() {
    return this.$scopedSlots.default?.();
  },
};
</script>

<script>
import { GlLabel, GlLoadingIcon } from '@gitlab/ui';
import getComplianceFrameworksQuery from 'ee/security_orchestration/graphql/queries/get_compliance_framework.query.graphql';
import { sprintf, n__, __ } from '~/locale';
import { mapShortIdsToFullGraphQlFormat } from 'ee/security_orchestration/components/policy_drawer/utils';
import { TYPE_COMPLIANCE_FRAMEWORK } from '~/graphql_shared/constants';
import {
  COMPLIANCE_FRAMEWORKS_DESCRIPTION,
  COMPLIANCE_FRAMEWORKS_DESCRIPTION_NO_PROJECTS,
} from 'ee/security_orchestration/components/policy_drawer/constants';

export default {
  name: 'ComplianceFrameworksToggleList',
  components: {
    GlLabel,
    GlLoadingIcon,
  },
  apollo: {
    complianceFrameworks: {
      query: getComplianceFrameworksQuery,
      variables() {
        return {
          fullPath: this.rootNamespacePath,
          complianceFrameworkIds: mapShortIdsToFullGraphQlFormat(
            TYPE_COMPLIANCE_FRAMEWORK,
            this.complianceFrameworkIds,
          ),
        };
      },
      update(data) {
        return data.namespace?.complianceFrameworks?.nodes || [];
      },
      error() {
        this.$emit('framework-query-error');
      },
    },
  },
  inject: ['rootNamespacePath'],
  props: {
    complianceFrameworkIds: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      complianceFrameworks: [],
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.complianceFrameworks?.loading;
    },
    header() {
      if (this.projectsLength === 0) {
        return COMPLIANCE_FRAMEWORKS_DESCRIPTION_NO_PROJECTS;
      }

      const projects = n__('project', 'projects', this.projectsLength);

      return sprintf(COMPLIANCE_FRAMEWORKS_DESCRIPTION, {
        projects: __(`${this.projectsLength} ${projects}`),
      });
    },
    projectsLength() {
      const allProjectsOfComplianceFrameworks = this.complianceFrameworks
        ?.flatMap(({ projects = {} }) => projects?.nodes?.map(({ id }) => id))
        .filter(Boolean);

      return Array.from(new Set(allProjectsOfComplianceFrameworks))?.length || 0;
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="loading" />

    <template v-else>
      <p class="gl-mb-3" data-testid="compliance-frameworks-header">
        {{ header }}
      </p>

      <div class="gl-display-flex gl-flex-wrap gl-gap-3">
        <gl-label
          v-for="item in complianceFrameworks"
          :key="item.id"
          :background-color="item.color"
          :description="item.description"
          :title="item.name"
          size="sm"
        />
      </div>
    </template>
  </div>
</template>

<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { __ } from '~/locale';
import ProjectsToken from './filter_tokens/projects_token.vue';
import ComplianceStandardNameToken from './filter_tokens/compliance_standard_name_token.vue';
import ComplianceCheckNameToken from './filter_tokens/compliance_check_name_token.vue';

export default {
  components: {
    GlFilteredSearch,
  },
  props: {
    projects: {
      type: Array,
      required: true,
      default: () => [],
    },
    groupPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    filterTokens() {
      return [
        {
          unique: true,
          type: 'standard',
          title: __('Standard'),
          entityType: 'standard',
          token: ComplianceStandardNameToken,
          operators: [{ value: 'matches', description: 'matches' }],
        },
        {
          unique: true,
          type: 'project',
          title: __('Project'),
          entityType: 'project',
          token: ProjectsToken,
          operators: [{ value: 'matches', description: 'matches' }],
          groupPath: this.groupPath,
          projects: this.projects,
        },
        {
          unique: true,
          type: 'check',
          title: __('Check'),
          entityType: 'check',
          token: ComplianceCheckNameToken,
          operators: [{ value: 'matches', description: 'matches' }],
        },
      ];
    },
  },
  methods: {
    onFilterSubmit(filters) {
      this.$emit('submit', filters);
    },
    handleFilterClear() {
      this.$emit('clear', []);
    },
  },
  i18n: {
    placeholder: __('Filter results'),
  },
};
</script>

<template>
  <div class="row-content-block gl-relative gl-border-0">
    <gl-filtered-search
      :placeholder="$options.i18n.placeholder"
      :available-tokens="filterTokens"
      @submit="onFilterSubmit"
      @clear="handleFilterClear"
    />
  </div>
</template>

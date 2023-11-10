<script>
import { debounce } from 'lodash';
import { GlButton, GlCollapsibleListbox, GlLabel } from '@gitlab/ui';
import { n__, s__, __ } from '~/locale';
import getComplianceFrameworkQuery from 'ee/graphql_shared/queries/get_compliance_framework.query.graphql';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import ComplianceFrameworkFormModal from 'ee/groups/settings/compliance_frameworks/components/form_modal.vue';

export default {
  i18n: {
    complianceFrameworkCreateButton: s__('SecurityOrchestration|Create new framework label'),
    complianceFrameworkHeader: s__('SecurityOrchestration|Select frameworks'),
    complianceFrameworkPlaceholder: s__('SecurityOrchestration|Choose framework labels'),
    noFrameworksText: s__('SecurityOrchestration|No compliance frameworks'),
    selectAllLabel: __('Select all'),
    clearAllLabel: __('Clear all'),
  },
  name: 'ComplianceFrameworkDropdown',
  components: {
    ComplianceFrameworkFormModal,
    GlButton,
    GlCollapsibleListbox,
    GlLabel,
  },
  apollo: {
    complianceFrameworks: {
      query: getComplianceFrameworkQuery,
      variables() {
        return {
          fullPath: this.fullPath,
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
  provide() {
    return {
      groupPath: this.fullPath,
      pipelineConfigurationFullPathEnabled: true,
      pipelineConfigurationEnabled: true,
    };
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    selectedFrameworkIds: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      complianceFrameworks: [],
      searchTerm: '',
    };
  },
  computed: {
    dropdownPlaceholder() {
      if (
        this.selectedFrameworkIds.length === this.complianceFrameworks?.length &&
        this.complianceFrameworks?.length > 0
      ) {
        return __('All frameworks selected');
      }
      if (this.selectedFrameworkIds.length) {
        return n__(
          '%d compliance framework selected',
          '%d compliance frameworks selected',
          this.selectedFrameworkIds.length,
        );
      }

      return this.$options.i18n.complianceFrameworkPlaceholder;
    },
    listBoxItems() {
      return (
        this.complianceFrameworks?.map(({ id, name, ...framework }) => ({
          value: id,
          text: name,
          ...framework,
        })) || []
      );
    },
    filteredListBoxItems() {
      return this.listBoxItems.filter(({ text }) =>
        text.toLowerCase().includes(this.searchTerm.toLowerCase()),
      );
    },
    complianceFrameworkIds() {
      return this.complianceFrameworks?.map(({ id }) => id);
    },
    loading() {
      return this.$apollo.queries.complianceFrameworks?.loading;
    },
  },
  created() {
    this.debouncedSearch = debounce(this.setSearchTerm, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  destroyed() {
    this.debouncedSearch.cancel();
  },
  methods: {
    showCreateFrameworkForm() {
      this.$refs.formModal.show();
    },
    setSearchTerm(searchTerm = '') {
      this.searchTerm = searchTerm.trim();
    },
    /**
     * Only works with ListBox multiple mode
     * Without multiple prop select method emits single id
     * and includes method won't work
     * @param ids selected ids
     */
    selectFrameworks(ids) {
      this.$emit('select', ids);
    },
    onComplianceFrameworkCreated() {
      this.$refs.formModal.hide();
    },
  },
};
</script>

<template>
  <div>
    <gl-collapsible-listbox
      block
      multiple
      searchable
      :header-text="$options.i18n.complianceFrameworkHeader"
      :loading="loading"
      :no-results-text="$options.i18n.noFrameworksText"
      :items="filteredListBoxItems"
      :reset-button-label="$options.i18n.clearAllLabel"
      :show-select-all-button-label="$options.i18n.selectAllLabel"
      :toggle-text="dropdownPlaceholder"
      :title="dropdownPlaceholder"
      :selected="selectedFrameworkIds"
      @reset="selectFrameworks([])"
      @search="debouncedSearch"
      @select="selectFrameworks"
      @select-all="selectFrameworks(complianceFrameworkIds)"
    >
      <template #list-item="{ item }">
        <gl-label
          size="sm"
          :background-color="item.color"
          :description="$options.i18n.editFramework"
          :title="item.text"
          :target="item.editPath"
        />
      </template>
      <template #footer>
        <div class="gl-border-t">
          <gl-button
            category="tertiary"
            class="gl-w-full gl-justify-content-start!"
            target="_blank"
            @click="showCreateFrameworkForm"
          >
            {{ $options.i18n.complianceFrameworkCreateButton }}
          </gl-button>
        </div>
      </template>
    </gl-collapsible-listbox>

    <compliance-framework-form-modal ref="formModal" @change="onComplianceFrameworkCreated" />
  </div>
</template>

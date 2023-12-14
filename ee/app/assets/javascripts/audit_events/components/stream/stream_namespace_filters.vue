<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { groupBy } from 'lodash';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { getSelectedOptionsText } from '~/lib/utils/listbox_helpers';
import { AUDIT_STREAMS_FILTERING } from '../../constants';

const MAX_OPTIONS_SHOWN = 3;

export default {
  components: {
    GlCollapsibleListbox,
  },
  inject: ['allGroups', 'allProjects'],
  props: {
    value: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
    };
  },
  computed: {
    allNamespaces() {
      return [...this.allGroups, ...this.allProjects];
    },
    filteredNamespaces() {
      if (this.searchTerm) {
        return fuzzaldrinPlus.filter(this.allNamespaces, this.searchTerm, { key: 'text' });
      }

      return this.allNamespaces;
    },
    options() {
      const groupedNamespaces = groupBy(this.filteredNamespaces, 'type');
      return Object.entries(groupedNamespaces).map(([type, namespaces]) => ({
        text: type,
        options: namespaces,
      }));
    },
    toggleText() {
      return getSelectedOptionsText({
        options: this.allNamespaces,
        selected: this.value.namespace,
        placeholder: this.$options.i18n.SELECT_NAMESPACE,
        maxOptionsShown: MAX_OPTIONS_SHOWN,
      });
    },
  },
  methods: {
    updateSearchTerm(searchTerm) {
      this.searchTerm = searchTerm.toLowerCase();
    },
    selectOption($event) {
      if (this.allGroups.find((group) => group.value === $event)) {
        this.$emit('input', { namespace: $event, type: 'group' });
      } else {
        this.$emit('input', { namespace: $event, type: 'project' });
      }
    },
    resetOptions() {
      this.$emit('input', { namespace: '', type: 'project' });
    },
  },
  i18n: {
    ...AUDIT_STREAMS_FILTERING,
  },
};
</script>

<template>
  <gl-collapsible-listbox
    id="audit-event-type-filter"
    :items="options"
    :selected="value.namespace"
    :header-text="$options.i18n.SELECT_NAMESPACE"
    :show-select-all-button-label="$options.i18n.SELECT_ALL"
    :reset-button-label="$options.i18n.UNSELECT_ALL"
    :no-results-text="$options.i18n.NO_RESULT_TEXT"
    :search-placeholder="$options.i18n.SEARCH_PLACEHOLDER"
    searchable
    infinite-scroll-loading
    toggle-class="gl-max-w-full"
    :toggle-text="toggleText"
    class="gl-max-w-full"
    @select="selectOption"
    @reset="resetOptions"
    @search="updateSearchTerm"
  />
</template>

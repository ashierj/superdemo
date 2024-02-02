<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { n__ } from '~/locale';

export default {
  name: 'VariableValuesListbox',
  components: {
    GlCollapsibleListbox,
  },
  props: {
    selected: {
      type: String,
      required: true,
    },
    items: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
    };
  },
  computed: {
    searchSummary() {
      return n__(
        'CiVariables|%d value found',
        'CiVariables|%d values found',
        this.filteredItems.length,
      );
    },
    filteredItems() {
      return this.items.filter((option) => option.text.toLowerCase().includes(this.searchTerm));
    },
  },
  methods: {
    onSearch(searchTerm) {
      this.searchTerm = searchTerm.trim().toLowerCase();
    },
  },
};
</script>
<template>
  <gl-collapsible-listbox
    :items="filteredItems"
    :toggle-text="selected"
    :selected="selected"
    :search-placeholder="s__('CiVariables|Search values')"
    :no-results-text="s__('CiVariables|No matching values')"
    searchable
    block
    fluid-width
    data-testid="pipeline-form-ci-variable-value-dropdown"
    @search="onSearch"
    @select="$emit('select', $event)"
  >
    <template #search-summary-sr-only>
      {{ searchSummary }}
    </template>
    <template #list-item="{ item: { text } }">
      <span data-testid="ci-variable-value-dropdown-item">
        <p class="gl-m-0">{{ text }}</p>
      </span>
    </template>
  </gl-collapsible-listbox>
</template>

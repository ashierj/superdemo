<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import {
  GlIcon,
  GlFilteredSearchToken,
  GlFilteredSearchSuggestion,
  GlLoadingIcon,
  GlIntersperse,
} from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
    GlLoadingIcon,
    GlIntersperse,
  },
  inject: ['licensesEndpoint'],
  props: {
    config: {
      type: Object,
      required: true,
    },
    // contains the token, with the selected operand (e.g.: '=') and the data (comma separated, e.g.: 'MIT, GNU')
    value: {
      type: Object,
      required: true,
    },
    active: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
      selectedLicenseNames: [],
    };
  },
  computed: {
    ...mapState('allDependencies', ['licenses', 'fetchingLicensesInProgress']),
    filteredLicenses() {
      if (!this.searchTerm) {
        return this.licenses;
      }

      const nameIncludesSearchTerm = (license) =>
        license.name.toLowerCase().includes(this.searchTerm);
      const isSelected = (license) => this.selectedLicenseNames.includes(license.name);

      return this.licenses.filter(
        (license) => nameIncludesSearchTerm(license) || isSelected(license),
      );
    },
    tokenValue() {
      return {
        ...this.value,
        // when the token is active (dropdown is open), we set the value to null to prevent an UX issue
        // in which only the last selected item is being displayed.
        // more information: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2381
        data: this.active ? null : this.selectedLicenseNames,
      };
    },
  },
  created() {
    this.fetchLicenses(this.licensesEndpoint);
  },
  methods: {
    ...mapActions('allDependencies', ['setLicensesEndpoint', 'fetchLicenses', 'setSearchFilters']),
    setSearchTerm(token) {
      // the data can be either a string or an array, in which case we don't want to perform the search
      if (typeof token.data === 'string') {
        this.searchTerm = token.data.toLowerCase();
      }
    },
    toggleSelectedLicense(name) {
      if (this.selectedLicenseNames.includes(name)) {
        this.selectedLicenseNames = this.selectedLicenseNames.filter((v) => v !== name);
      } else {
        this.selectedLicenseNames.push(name);
      }
    },
  },
};
</script>

<template>
  <gl-filtered-search-token
    :config="config"
    v-bind="{ ...$props, ...$attrs }"
    :multi-select-values="selectedLicenseNames"
    :value="tokenValue"
    v-on="$listeners"
    @select="toggleSelectedLicense"
    @input="setSearchTerm"
  >
    <template #view>
      <gl-intersperse data-testid="selected-licenses">
        <span v-for="selectedLicense in selectedLicenseNames" :key="selectedLicense">{{
          selectedLicense
        }}</span>
      </gl-intersperse>
    </template>
    <template #suggestions>
      <gl-loading-icon v-if="fetchingLicensesInProgress" size="sm" />
      <template v-else>
        <gl-filtered-search-suggestion
          v-for="license in filteredLicenses"
          :key="license.spdxIdentifier"
          :value="license.name"
        >
          <div class="gl-display-flex gl-align-items-center">
            <gl-icon
              v-if="config.multiSelect"
              data-testid="check-icon"
              name="check"
              class="gl-mr-3 gl-flex-shrink-0 gl-text-gray-700"
              :class="{
                'gl-visibility-hidden': !selectedLicenseNames.includes(license.name),
              }"
            />
            <span>{{ license.name }}</span>
          </div>
        </gl-filtered-search-suggestion>
      </template>
    </template>
  </gl-filtered-search-token>
</template>

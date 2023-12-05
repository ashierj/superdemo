<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
} from '@gitlab/ui';

import { INPUT_DEBOUNCE, CUSTODY_REPORT_PARAMETER } from 'ee/compliance_dashboard/constants';
import { isValidSha1Hash } from '~/lib/utils/text_utility';
import { s__ } from '~/locale';

export default {
  name: 'ExportApp',
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
  },
  props: {
    mergeCommitsCsvExportPath: {
      type: String,
      required: false,
      default: '',
    },
    frameworksCsvExportPath: {
      type: String,
      required: false,
      default: '',
    },
    violationsCsvExportPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      exportCustodyCommitDisclosure: false,
      validMergeCommitHash: null,
    };
  },
  computed: {
    exportItems() {
      const items = [];

      if (this.violationsCsvExportPath) {
        items.push({
          value: 'violations_export',
          text: this.$options.i18n.violationsExportTitle,
          href: this.violationsCsvExportPath,
          extraAttrs: {
            'data-testid': 'violations-export',
            'data-track-action': 'click_export',
            'data-track-label': 'export_all_violations',
          },
        });
      }

      if (this.frameworksCsvExportPath) {
        items.push({
          value: 'frameworks_export',
          text: this.$options.i18n.frameworksExportTitle,
          href: this.frameworksCsvExportPath,
          extraAttrs: {
            'data-testid': 'frameworks-export',
            'data-track-action': 'click_export',
            'data-track-label': 'export_all_frameworks',
          },
        });
      }

      if (this.mergeCommitsCsvExportPath) {
        items.push({
          value: 'custody_commit_export',
          text: this.$options.i18n.custodyCommitsExportTitle,
          href: this.mergeCommitsCsvExportPath,
          extraAttrs: {
            'data-testid': 'custody-commits-export',
            'data-track-action': 'click_export',
            'data-track-label': 'export_merge_commits',
          },
        });

        items.push({
          value: 'custody-commit-export',
          text: this.$options.i18n.custodyCommitExportTitle,
          action: () => {
            this.exportCustodyCommitDisclosure = true;
          },
          extraAttrs: {
            'data-testid': 'custody-commit-export',
            'data-track-action': 'click_export',
            'data-track-label': 'export_merge_commit',
          },
        });
      }

      return items;
    },
    exportDropdownTitle() {
      return this.exportCustodyCommitDisclosure
        ? this.$options.i18n.custodyCommitExportTitle
        : this.$options.i18n.defaultExportDropdownTitle;
    },
    mergeCommitButtonDisabled() {
      return !this.validMergeCommitHash;
    },
  },
  methods: {
    onInput(value) {
      this.validMergeCommitHash = isValidSha1Hash(value);
    },
  },

  i18n: {
    defaultExportDropdownTitle: s__(
      'Compliance Center Export|Send email of the chosen report as CSV',
    ),
    violationsExportTitle: s__('Compliance Center Export|Export violations report'),
    frameworksExportTitle: s__('Compliance Center Export|Export list of project frameworks'),
    custodyCommitsExportTitle: s__('Compliance Center Export|Export chain of custody report'),
    custodyCommitExportTitle: s__(
      'Compliance Center Export|Export custody report of a specific commit',
    ),
    mergeCommitExampleLabel: s__('Compliance Center Export|Example: 2dc6aa3'),
    mergeCommitInvalidMessage: s__('Compliance Center Export|Invalid hash'),
    mergeCommitButtonText: s__('Compliance Center Export|Export custody report'),
    tooltipExportText: s__('Compliance Center Export|Export as CSV'),
    tooltipSizeLimitText: s__('Compliance Center Export|(limited to 15 MB)'),
  },
  inputDebounce: INPUT_DEBOUNCE,
  custodyReportParamater: CUSTODY_REPORT_PARAMETER,
};
</script>
<template>
  <gl-disclosure-dropdown
    fluid-width
    bordered
    icon="export"
    toggle-text="Export"
    data-testid="exports-disclosure-dropdown"
  >
    <template #header>
      <div class="gl-border-b gl-border-b-gray-200 gl-p-4">
        <span class="gl-font-weight-bold">
          {{ exportDropdownTitle }}
        </span>
      </div>
    </template>

    <template v-if="exportCustodyCommitDisclosure">
      <gl-form :action="mergeCommitsCsvExportPath" class="gl-px-3" method="GET">
        <gl-form-group
          :invalid-feedback="$options.i18n.mergeCommitInvalidMessage"
          :state="validMergeCommitHash"
          label-size="sm"
          label-for="merge-commits-export-custody-report"
          class="gl-mb-2"
        >
          <gl-form-input
            id="merge-commits-export-custody-report"
            :name="$options.custodyReportParamater"
            :debounce="$options.inputDebounce"
            :placeholder="$options.i18n.mergeCommitExampleLabel"
            @input="onInput"
          />
        </gl-form-group>
        <div class="gl-float-right gl-my-3">
          <gl-button size="small" @click="exportCustodyCommitDisclosure = false">
            {{ __('Cancel') }}
          </gl-button>
          <gl-button
            size="small"
            type="submit"
            :disabled="mergeCommitButtonDisabled"
            variant="confirm"
            data-testid="merge-commit-submit-button"
            class="disable-hover"
            data-track-action="click_export"
            data-track-label="export_custody_report"
            >{{ $options.i18n.mergeCommitButtonText }}</gl-button
          >
        </div>
      </gl-form>
    </template>
    <template v-for="(item, index) in exportItems" v-else>
      <gl-disclosure-dropdown-item :key="index" :item="item" />
    </template>
  </gl-disclosure-dropdown>
</template>

<script>
import { GlAccordion, GlAccordionItem } from '@gitlab/ui';
import { STANDARDS_ADHERENCE_CHECK_LABELS } from 'ee/compliance_dashboard/components/standards_adherence_report/constants';
import AdherencesBaseTable from './base_table.vue';

export default {
  name: 'GroupChecks',
  components: {
    GlAccordion,
    GlAccordionItem,
    AdherencesBaseTable,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
    filters: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      hasStandardsAdherenceFetchError: false,
      hasFilterValueError: false,
      hasRawTextError: false,
    };
  },
  checks: STANDARDS_ADHERENCE_CHECK_LABELS,
};
</script>

<template>
  <div class="gl-border-t" data-testid="adherences-grouped-by-checks">
    <gl-accordion :auto-collapse="false" :header-level="1">
      <span
        v-for="(value, key, index) in $options.checks"
        :key="index"
        class="gl-display-flex gl-md-flex-direction-row gl-align-items-flex-start gl-border-b"
        data-testid="grouped-check"
      >
        <gl-accordion-item class="gl-my-4!" :title="value">
          <adherences-base-table
            :is-loading="false"
            :group-path="groupPath"
            :check="key"
            :filters="filters"
          />
        </gl-accordion-item>
      </span>
    </gl-accordion>
  </div>
</template>

<style>
.gl-accordion-item-header {
  .gl-button-text {
    font-weight: bold;
    color: black;
    font-size: 14px;
    margin-left: 10px;
  }
}
</style>

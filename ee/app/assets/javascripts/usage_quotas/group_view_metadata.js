import { __ } from '~/locale';
import { storageTabMetadata } from '~/usage_quotas/group_view_metadata';
import { STORAGE_TAB_METADATA_EL_SELECTOR } from '~/usage_quotas/constants';
import PipelineUsageApp from './pipelines/components/app.vue';
import { parseProvideData as parseStorageTabProvideData } from './storage/utils';
import { parseProvideData as parsePipelinesTabProvideData } from './pipelines/utils';
import { PIPELINES_TAB_METADATA_EL_SELECTOR } from './constants';
import { getCodeSuggestionsTabMetadata } from './code_suggestions/tab_metadata';
import { getSeatTabMetadata } from './seats/tab_metadata';

export const usageQuotasViewProvideData = {
  ...parseStorageTabProvideData(document.querySelector(STORAGE_TAB_METADATA_EL_SELECTOR)),
  ...parsePipelinesTabProvideData(document.querySelector(PIPELINES_TAB_METADATA_EL_SELECTOR)),
};

const getPipelineTabMetadata = () => {
  const el = document.querySelector(PIPELINES_TAB_METADATA_EL_SELECTOR);

  if (!el) return false;

  return {
    title: __('Pipelines'),
    component: PipelineUsageApp,
  };
};

export const usageQuotasTabsMetadata = [
  getSeatTabMetadata(),
  getCodeSuggestionsTabMetadata(),
  getPipelineTabMetadata(),
  storageTabMetadata,
];

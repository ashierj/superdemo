import { __ } from '~/locale';
import { storageTabMetadata } from '~/usage_quotas/group_view_metadata';
import { STORAGE_TAB_METADATA_EL_SELECTOR } from '~/usage_quotas/constants';
import PipelineUsageApp from './pipelines/components/app.vue';
import { parseProvideData as parseStorageTabProvideData } from './storage/utils';
import { parseProvideData as parsePipelinesTabProvideData } from './pipelines/utils';
import { PIPELINES_TAB_METADATA_EL_SELECTOR } from './constants';

export const usageQuotasViewProvideData = {
  ...parseStorageTabProvideData(document.querySelector(STORAGE_TAB_METADATA_EL_SELECTOR)),
  ...parsePipelinesTabProvideData(document.querySelector(PIPELINES_TAB_METADATA_EL_SELECTOR)),
};

const pipelineTabMetadata = {
  title: __('Pipelines'),
  component: PipelineUsageApp,
  shouldRender: () => document.querySelector(PIPELINES_TAB_METADATA_EL_SELECTOR),
};

export const usageQuotasTabsMetadata = [pipelineTabMetadata, storageTabMetadata].filter((tab) =>
  tab.shouldRender(),
);

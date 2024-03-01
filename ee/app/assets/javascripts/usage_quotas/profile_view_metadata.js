import { getStorageTabMetadata } from '~/usage_quotas/storage/tab_metadata';
import { getPipelineTabMetadata } from './pipelines/tab_metadata';

export const usageQuotasTabsMetadata = [getPipelineTabMetadata(), getStorageTabMetadata()].filter(
  Boolean,
);

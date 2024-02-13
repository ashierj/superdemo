import { storageTabMetadata } from '~/usage_quotas/group_view_metadata';
import { STORAGE_TAB_METADATA_EL_SELECTOR } from '~/usage_quotas/constants';
import { parseProvideData as parseStorageTabProvideData } from './storage/utils';

export const usageQuotasViewProvideData = {
  ...parseStorageTabProvideData(document.querySelector(STORAGE_TAB_METADATA_EL_SELECTOR)),
};

export const usageQuotasTabsMetadata = [storageTabMetadata];

import customApolloProvider from 'ee/usage_quotas/shared/provider';
import { getStorageTabMetadata } from '~/usage_quotas/storage/tab_metadata';
import { GROUP_VIEW_TYPE } from '~/usage_quotas/constants';
import { getSeatTabMetadata } from './seats/tab_metadata';
import { getCodeSuggestionsTabMetadata } from './code_suggestions/tab_metadata';
import { getPipelineTabMetadata } from './pipelines/tab_metadata';
import { getTransferTabMetadata } from './transfer/tab_metadata';

export const usageQuotasTabsMetadata = [
  getSeatTabMetadata(),
  getCodeSuggestionsTabMetadata(),
  getPipelineTabMetadata(),
  getStorageTabMetadata({ customApolloProvider }),
  getTransferTabMetadata({ viewType: GROUP_VIEW_TYPE }),
];

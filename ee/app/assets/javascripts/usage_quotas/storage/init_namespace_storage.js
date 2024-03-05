import Vue from 'vue';
import VueApollo from 'vue-apollo';
import customApolloProvider from 'ee/usage_quotas/shared/provider';
import { getStorageTabMetadata } from '~/usage_quotas/storage/tab_metadata';
import { GROUP_VIEW_TYPE } from '~/usage_quotas/constants';

Vue.use(VueApollo);

export default () => {
  const storageTabMetadata = getStorageTabMetadata({
    viewType: GROUP_VIEW_TYPE,
    includeEl: true,
    customApolloProvider,
  });

  if (!storageTabMetadata) return false;

  return new Vue(storageTabMetadata.component);
};

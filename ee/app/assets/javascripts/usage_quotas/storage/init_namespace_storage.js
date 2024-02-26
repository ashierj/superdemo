import Vue from 'vue';
import VueApollo from 'vue-apollo';
import customApolloProvider from 'ee/usage_quotas/shared/provider';
import { getStorageTabMetadata } from '~/usage_quotas/storage/tab_metadata';

Vue.use(VueApollo);

export default () => {
  const storageTabMetadata = getStorageTabMetadata({ includeEl: true, customApolloProvider });

  if (!storageTabMetadata) return false;

  return new Vue(storageTabMetadata.component);
};

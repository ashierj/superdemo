import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GROUP_VIEW_TYPE, PROJECT_VIEW_TYPE } from '~/usage_quotas/constants';
import { getTransferTabMetadata } from './tab_metadata';

export const initGroupTransferApp = () => {
  const transferTabMetadata = getTransferTabMetadata({
    viewType: GROUP_VIEW_TYPE,
    includeEl: true,
  });

  if (!transferTabMetadata) return false;

  Vue.use(VueApollo);

  return new Vue(transferTabMetadata.component);
};

export const initProjectTransferApp = () => {
  const transferTabMetadata = getTransferTabMetadata({
    viewType: PROJECT_VIEW_TYPE,
    includeEl: true,
  });

  if (!transferTabMetadata) return false;

  Vue.use(VueApollo);

  return new Vue(transferTabMetadata.component);
};

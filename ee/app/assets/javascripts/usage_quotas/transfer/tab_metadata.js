import VueApollo from 'vue-apollo';
import { __ } from '~/locale';
import createDefaultClient from '~/lib/graphql';
import { GROUP_VIEW_TYPE, PROJECT_VIEW_TYPE } from '~/usage_quotas/constants';
import {
  GROUP_TRANSFER_TAB_METADATA_EL_SELECTOR,
  PROJECT_TRANSFER_TAB_METADATA_EL_SELECTOR,
} from '../constants';
import GroupTransferApp from './components/group_transfer_app.vue';
import ProjectTransferApp from './components/project_transfer_app.vue';

export const parseProvideData = (el) => {
  const { fullPath } = el.dataset;
  return {
    fullPath,
  };
};

export const getTransferTabMetadata = (viewType, withMountElement = false) => {
  let elSelector;
  let vueComponent;

  if (viewType === GROUP_VIEW_TYPE) {
    elSelector = GROUP_TRANSFER_TAB_METADATA_EL_SELECTOR;
    vueComponent = GroupTransferApp;
  } else if (viewType === PROJECT_VIEW_TYPE) {
    elSelector = PROJECT_TRANSFER_TAB_METADATA_EL_SELECTOR;
    vueComponent = ProjectTransferApp;
  }

  const el = document.querySelector(elSelector);

  if (!el) return false;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const transferTabMetadata = {
    title: __('Transfer'),
    component: {
      name: 'TransferTab',
      apolloProvider,
      provide: parseProvideData(el),
      render(createElement) {
        return createElement(vueComponent);
      },
    },
  };
  if (withMountElement) {
    transferTabMetadata.component.el = el;
  }

  return transferTabMetadata;
};

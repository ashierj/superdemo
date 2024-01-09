import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import { mergeRequestApprovalSettingsMappers } from '../mappers';
import createStore from '../stores';
import approvalSettingsModule from '../stores/modules/approval_settings';
import GroupSettingsApp from './app.vue';

const mountGroupApprovalSettings = (el) => {
  if (!el) {
    return null;
  }

  const { defaultExpanded, approvalSettingsPath } = el.dataset;
  const store = createStore({
    approvalSettings: approvalSettingsModule(mergeRequestApprovalSettingsMappers),
  });

  Vue.use(GlToast);

  return new Vue({
    el,
    store,
    render: (createElement) =>
      createElement(GroupSettingsApp, {
        props: {
          defaultExpanded: parseBoolean(defaultExpanded),
          approvalSettingsPath,
        },
      }),
  });
};

export { mountGroupApprovalSettings };

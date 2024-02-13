import Vue from 'vue';
import VueApollo from 'vue-apollo';
import apolloProvider from 'ee/usage_quotas/shared/provider';
import NamespaceStorageApp from '~/usage_quotas/storage/components/namespace_storage_app.vue';
import { STORAGE_TAB_METADATA_EL_SELECTOR } from '~/usage_quotas/constants';
import { parseProvideData } from './utils';

Vue.use(VueApollo);

export default () => {
  const el = document.querySelector(STORAGE_TAB_METADATA_EL_SELECTOR);

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    apolloProvider,
    name: 'NamespaceStorageApp',
    provide: parseProvideData(el),
    render(createElement) {
      return createElement(NamespaceStorageApp);
    },
  });
};

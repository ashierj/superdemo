import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { parseBoolean } from '~/lib/utils/common_utils';
import { storageTypeHelpPaths as helpLinks } from '~/usage_quotas/storage/constants';
import apolloProvider from 'ee/usage_quotas/shared/provider';
import { NAMESPACE_ENFORCEMENT_TYPE, PROJECT_ENFORCEMENT_TYPE } from './constants';
import NamespaceStorageApp from './components/namespace_storage_app.vue';

Vue.use(VueApollo);

export default () => {
  const el = document.getElementById('js-storage-counter-app');

  if (!el) {
    return false;
  }

  const {
    namespaceId,
    namespacePath,
    userNamespace,
    defaultPerPage,
    namespacePlanName,
    purchaseStorageUrl,
    buyAddonTargetAttr,
    enforcementType,
    totalRepositorySizeExcess,
  } = el.dataset;

  const namespacePlanStorageIncluded = el.dataset.namespacePlanStorageIncluded
    ? Number(el.dataset.namespacePlanStorageIncluded)
    : 0;
  const isUsingNamespaceEnforcement = enforcementType === NAMESPACE_ENFORCEMENT_TYPE;
  const isUsingProjectEnforcement = enforcementType === PROJECT_ENFORCEMENT_TYPE;
  const isUsingProjectEnforcementWithLimits =
    isUsingProjectEnforcement && namespacePlanStorageIncluded !== 0;
  const isUsingProjectEnforcementWithNoLimits =
    isUsingProjectEnforcement && namespacePlanStorageIncluded === 0;

  return new Vue({
    el,
    apolloProvider,
    name: 'NamespaceStorageApp',
    provide: {
      namespaceId,
      namespacePath,
      userNamespace: parseBoolean(userNamespace),
      defaultPerPage: Number(defaultPerPage),
      namespacePlanName,
      namespacePlanStorageIncluded,
      purchaseStorageUrl,
      buyAddonTargetAttr,
      totalRepositorySizeExcess: totalRepositorySizeExcess && Number(totalRepositorySizeExcess),
      isUsingNamespaceEnforcement,
      isUsingProjectEnforcementWithLimits,
      isUsingProjectEnforcementWithNoLimits,
      helpLinks,
    },
    render(createElement) {
      return createElement(NamespaceStorageApp);
    },
  });
};

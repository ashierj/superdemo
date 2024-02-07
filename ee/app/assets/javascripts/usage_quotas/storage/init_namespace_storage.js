import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { parseBoolean } from '~/lib/utils/common_utils';
import { storageTypeHelpPaths as helpLinks } from '~/usage_quotas/storage/constants';
import NamespaceStorageApp from '~/usage_quotas/storage/components/namespace_storage_app.vue';
import apolloProvider from 'ee/usage_quotas/shared/provider';
import { NAMESPACE_ENFORCEMENT_TYPE, PROJECT_ENFORCEMENT_TYPE } from './constants';

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
    isInNamespaceLimitsPreEnforcement,
    totalRepositorySizeExcess,
  } = el.dataset;

  const perProjectStorageLimit = el.dataset.perProjectStorageLimit
    ? Number(el.dataset.perProjectStorageLimit)
    : 0;
  const namespaceStorageLimit = el.dataset.namespaceStorageLimit
    ? Number(el.dataset.namespaceStorageLimit)
    : 0;
  const isUsingNamespaceEnforcement = enforcementType === NAMESPACE_ENFORCEMENT_TYPE;
  const isUsingProjectEnforcement = enforcementType === PROJECT_ENFORCEMENT_TYPE;
  const isUsingProjectEnforcementWithLimits =
    isUsingProjectEnforcement && perProjectStorageLimit !== 0;
  const isUsingProjectEnforcementWithNoLimits =
    isUsingProjectEnforcement && perProjectStorageLimit === 0;

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
      perProjectStorageLimit,
      namespaceStorageLimit,
      purchaseStorageUrl,
      buyAddonTargetAttr,
      isInNamespaceLimitsPreEnforcement: parseBoolean(isInNamespaceLimitsPreEnforcement),
      totalRepositorySizeExcess: totalRepositorySizeExcess && Number(totalRepositorySizeExcess),
      isUsingNamespaceEnforcement,
      isUsingProjectEnforcementWithLimits,
      isUsingProjectEnforcementWithNoLimits,
      customSortKey: isUsingProjectEnforcementWithLimits ? 'EXCESS_REPO_STORAGE_SIZE_DESC' : null,
      helpLinks,
    },
    render(createElement) {
      return createElement(NamespaceStorageApp);
    },
  });
};

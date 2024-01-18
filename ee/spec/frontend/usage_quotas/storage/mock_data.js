import { storageTypeHelpPaths } from '~/usage_quotas/storage/constants';
import {
  mockGetNamespaceStorageGraphQLResponse,
  mockGetProjectListStorageGraphQLResponse,
} from 'jest/usage_quotas/storage/mock_data';

export const { namespace } = mockGetNamespaceStorageGraphQLResponse.data;
export const projectList = mockGetProjectListStorageGraphQLResponse.data.namespace.projects.nodes;

export const defaultNamespaceProvideValues = {
  namespaceId: '0',
  namespacePath: 'GitLab',
  userNamespace: false,
  defaultPerPage: 20,
  purchaseStorageUrl: 'some-fancy-url',
  buyAddonTargetAttr: '_blank',
  namespacePlanName: 'Free',
  isInNamespaceLimitsPreEnforcement: false,
  perProjectStorageLimit: 10737418240,
  namespaceStorageLimit: 5368709120,
  totalRepositorySizeExcess: '0',
  isUsingProjectEnforcementWithLimits: false,
  isUsingProjectEnforcementWithNoLimits: false,
  isUsingNamespaceEnforcement: true,
  helpLinks: storageTypeHelpPaths,
};

export const statisticsCardDefaultProps = {
  purchasedStorage: 0,
  usedStorage: namespace.rootStorageStatistics.storageSize,
  loading: false,
};

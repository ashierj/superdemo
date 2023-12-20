import mockGetNamespaceStorageGraphQLResponse from 'test_fixtures/graphql/usage_quotas/storage/namespace_storage.query.graphql.json';
import mockGetProjectListStorageGraphQLResponse from 'test_fixtures/graphql/usage_quotas/storage/project_list_storage.query.graphql.json';
import { storageTypeHelpPaths } from '~/usage_quotas/storage/constants';

export { mockGetNamespaceStorageGraphQLResponse };
export { mockGetProjectListStorageGraphQLResponse };

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

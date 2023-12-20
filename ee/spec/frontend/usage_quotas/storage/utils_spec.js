import { parseGetStorageResults } from 'ee/usage_quotas/storage/utils';
import { mockGetNamespaceStorageGraphQLResponse } from './mock_data';

describe('parseGetStorageResults', () => {
  it('returns the object keys we use', () => {
    const objectKeys = Object.keys(
      parseGetStorageResults(mockGetNamespaceStorageGraphQLResponse.data),
    );
    expect(objectKeys).toEqual([
      'additionalPurchasedStorageSize',
      'actualRepositorySizeLimit',
      'containsLockedProjects',
      'repositorySizeExcessProjectCount',
      'totalRepositorySize',
      'totalRepositorySizeExcess',
      'totalUsage',
      'rootStorageStatistics',
      'limit',
    ]);
  });
});

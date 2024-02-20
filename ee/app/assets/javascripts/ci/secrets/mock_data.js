const mockSecretsData = [
  {
    name: 'product/client-tokens',
    labels: ['env::staging', 'env::production'],
    lastAccessed: '2024-01-22T07:12:44.833Z',
    createdAt: '2024-01-24T08:04:26.024Z',
  },
  {
    name: 'security-token-project2',
    labels: ['env::production', 'shell'],
    lastAccessed: '2024-01-21T23:13:37.227Z',
    createdAt: '2024-01-19T11:59:43.516Z',
  },
  {
    name: 'personal-tokens',
    labels: [],
    lastAccessed: '2024-01-19T21:01:38.925Z',
    createdAt: '2024-01-17T05:51:54.602Z',
  },
  {
    name: 'token-deployment',
    labels: [],
    lastAccessed: '2024-01-16T23:13:31.548Z',
    createdAt: '2024-01-20T17:12:33.882Z',
  },
  {
    name: 'runner-token-mac',
    labels: [],
    lastAccessed: '2024-01-06T07:50:58.308Z',
    createdAt: '2024-01-15T16:35:38.326Z',
  },
  {
    name: 'aws-db-prod-credentials',
    labels: [],
    lastAccessed: '2024-01-05T11:47:59.454Z',
    createdAt: '2024-01-19T10:37:41.135Z',
  },
  {
    name: 'runner-token-linux',
    labels: [],
    lastAccessed: '2024-01-02T16:41:08.551Z',
    createdAt: '2024-01-14T18:52:56.258Z',
  },
  {
    name: 'SSH-KEY-1',
    labels: [],
    lastAccessed: '2023-12-29T22:18:31.562Z',
    createdAt: '2023-12-30T01:29:14.394Z',
  },
  {
    name: 'group-ID',
    labels: ['shell'],
    lastAccessed: '2023-12-29T04:30:10.220Z',
    createdAt: '2024-01-21T17:34:33.544Z',
  },
];

export const mockGroupSecretsData = mockSecretsData.map((secret, index) => ({
  key: `group_secret_${index}`,
  ...secret,
}));

export const mockProjectSecretsData = mockSecretsData.map((secret, index) => ({
  key: `project_secret_${index}`,
  ...secret,
}));

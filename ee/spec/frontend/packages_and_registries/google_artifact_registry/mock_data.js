export const headerData = {
  projectId: 'dev-package-container-96a3ff34',
  repository: 'myrepo',
  gcpRepositoryUrl:
    'https://console.cloud.google.com/artifacts/docker/dev-package-container-96a3ff34/us-east1/myrepo',
};

export const imageData = {
  image: 'alpine',
  digest: 'sha256:1234567890abcdef1234567890abcdef12345678',
  tags: ['latest', 'v1.0.0', 'v1.0.1'],
  buildTime: '2019-01-01T00:00:00Z',
  updateTime: '2020-01-01T00:00:00Z',
};

export const getArtifactsQueryResponse = {
  data: {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      googleCloudPlatformArtifactRegistryRepositoryArtifacts: {
        ...headerData,
        nodes: [
          {
            ...imageData,
          },
        ],
      },
    },
  },
};

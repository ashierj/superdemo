export const headerData = {
  project: 'dev-package-container-96a3ff34',
  repository: 'myrepo',
  gcpRepositoryUrl:
    'https://console.cloud.google.com/artifacts/docker/dev-package-container-96a3ff34/us-east1/myrepo',
};

export const getArtifactsQueryResponse = {
  data: {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      googleCloudPlatformArtifactRegistryRepositoryArtifacts: {
        ...headerData,
      },
    },
  },
};

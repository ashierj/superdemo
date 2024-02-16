export const headerData = {
  projectId: 'dev-package-container-96a3ff34',
  repository: 'myrepo',
  gcpRepositoryUrl:
    'https://console.cloud.google.com/artifacts/docker/dev-package-container-96a3ff34/us-east1/myrepo',
};

export const imageData = {
  name:
    'projects/dev-package-container-96a3ff34/locations/us-east1/repositories/myrepo/dockerImages/alpine@sha256:6a0657acfef760bd9e293361c9b558e98e7d740ed0dffca823d17098a4ffddf5',
  image: 'alpine',
  digest: 'sha256:1234567890abcdef1234567890abcdef12345678',
  tags: ['latest', 'v1.0.0', 'v1.0.1'],
  buildTime: '2019-01-01T00:00:00Z',
  updateTime: '2020-01-01T00:00:00Z',
};

export const imageDetailsFields = {
  uri:
    'us-east1-docker.pkg.dev/dev-package-container-96a3ff34/myrepo/alpine@sha256:6a0657acfef760bd9e293361c9b558e98e7d740ed0dffca823d17098a4ffddf5',
  imageSizeBytes: 2827903,
  uploadTime: '2023-12-07T11:48:47.598511Z',
  mediaType: 'application/vnd.docker.distribution.manifest.v2+json',
  project: 'dev-package-container-96a3ff34',
  location: 'us-east1',
  repository: 'myrepo',
  artifactRegistryImageUrl:
    'https://us-east1-docker.pkg.dev/dev-package-container-96a3ff34/myrepo/alpine@sha256:6a0657acfef760bd9e293361c9b558e98e7d740ed0dffca823d17098a4ffddf5',
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

export const getArtifactDetailsQueryResponse = {
  data: {
    googleCloudRegistryArtifactDetails: {
      ...imageData,
      ...imageDetailsFields,
    },
  },
};

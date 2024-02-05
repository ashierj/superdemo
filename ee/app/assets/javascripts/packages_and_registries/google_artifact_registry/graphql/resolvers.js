const resolvers = {
  Project: {
    googleCloudPlatformArtifactRegistryRepositoryArtifacts: () => ({
      projectId: 'dev-package-container-96a3ff34',
      repository: 'myrepo',
      gcpRepositoryUrl:
        'https://console.cloud.google.com/artifacts/docker/dev-package-container-96a3ff34/us-east1/myrepo',
      nodes: [
        {
          name:
            'projects/dev-package-container-96a3ff34/locations/us-east1/repositories/myrepo/dockerImages/alpine@sha256:6a0657acfef760bd9e293361c9b558e98e7d740ed0dffca823d17098a4ffddf5',
          uri:
            'us-east1-docker.pkg.dev/dev-package-container-96a3ff34/myrepo/alpine@sha256:6a0657acfef760bd9e293361c9b558e98e7d740ed0dffca823d17098a4ffddf5',
          buildTime: '2022-12-07T11:48:50.840751Z',
          updateTime: '2023-12-07T11:48:50.840751Z',
          image:
            'alpinealpinealpinealpinealpinealpinealpinealpinealpinealpinealpinealpinealpinealpinealpinealpinealpinealpinealpinealpine',
          digest: 'sha256:6a0657acfef760bd9e293361c9b558e98e7d740ed0dffca823d17098a4ffddf5',
          tags: [
            '6a0657acfef760bd9e293361c9b558e98e7d740ed0dffca823d17098a4ffddf5',
            '6a0657acfef760bd9e293361c9b558e98e7d740ed0dffca823d17098a4ffddf5',
            '3.15',
            '3.15.11',
            '3.15.12',
          ],
        },
      ],
    }),
  },
};

export default resolvers;

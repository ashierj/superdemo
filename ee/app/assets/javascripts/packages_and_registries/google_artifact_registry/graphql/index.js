import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import resolvers from 'ee_component/packages_and_registries/google_artifact_registry/graphql/resolvers';
import getArtifactDetailsQuery from 'ee_component/packages_and_registries/google_artifact_registry/graphql/queries/get_artifact_details.query.graphql';

Vue.use(VueApollo);

const defaultClient = createDefaultClient(resolvers);

defaultClient.cache.writeQuery({
  query: getArtifactDetailsQuery,
  variables: {
    project: 'dev-package-container-96a3ff34',
    location: 'us-east1',
    repository: 'myrepo',
    // eslint-disable-next-line @gitlab/require-i18n-strings
    image: 'alpine@sha256:6a0657acfef760bd9e293361c9b558e98e7d740ed0dffca823d17098a4ffddf5',
  },
  data: {
    googleCloudRegistryArtifactDetails: {
      name:
        'projects/dev-package-container-96a3ff34/locations/us-east1/repositories/myrepo/dockerImages/alpine@sha256:6a0657acfef760bd9e293361c9b558e98e7d740ed0dffca823d17098a4ffddf5',
      uri:
        'us-east1-docker.pkg.dev/dev-package-container-96a3ff34/myrepo/alpine@sha256:6a0657acfef760bd9e293361c9b558e98e7d740ed0dffca823d17098a4ffddf5',
      tags: [
        '3.15',
        '3.15.11',
        '3.15',
        '3.15.11',
        '6a0657acfef760bd9e293361c9b558e98e7d740ed0dffca823d17098a4ffddf5',
        '3.15.11',
        '3.15',
        '3.15.11',
        '3.15',
        '3.15.11',
        '3.15',
        '3.15.11',
        '3.15',
        '3.15.11',
        '3.15',
        '3.15.11',
      ],
      imageSizeBytes: 2827903,
      uploadTime: '2023-12-07T11:48:47.598511Z',
      mediaType: 'application/vnd.docker.distribution.manifest.v2+json',
      buildTime: '2023-11-30T23:23:11.980068941Z',
      updateTime: '2023-12-07T11:48:50.840751Z',
      project: 'dev-package-container-96a3ff34',
      location: 'us-east1',
      repository: 'myrepo',
      image: 'alpine',
      digest: 'sha256:6a0657acfef760bd9e293361c9b558e98e7d740ed0dffca823d17098a4ffddf5',
      artifactRegistryImageUrl:
        'https://us-east1-docker.pkg.dev/dev-package-container-96a3ff34/myrepo/alpine@sha256:6a0657acfef760bd9e293361c9b558e98e7d740ed0dffca823d17098a4ffddf5',
    },
  },
});

export const apolloProvider = new VueApollo({
  defaultClient,
});

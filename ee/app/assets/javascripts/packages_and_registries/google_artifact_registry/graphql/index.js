import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import resolvers from 'ee_component/packages_and_registries/google_artifact_registry/graphql/resolvers';

Vue.use(VueApollo);

const defaultClient = createDefaultClient(resolvers);

export const apolloProvider = new VueApollo({
  defaultClient,
});

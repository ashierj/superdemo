import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import { apolloProvider } from 'ee_component/packages_and_registries/google_artifact_registry/graphql/index';
import GoogleArtifactRegistryListPage from 'ee_component/packages_and_registries/google_artifact_registry/pages/list.vue';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-google-artifact-registry');
  const { fullPath, settingsPath } = el.dataset;

  const attachMainComponent = () =>
    new Vue({
      el,
      name: 'GoogleArtifactRegistryApp',
      apolloProvider,
      provide: {
        fullPath,
        settingsPath,
      },
      render(createElement) {
        return createElement(GoogleArtifactRegistryListPage);
      },
    });

  return {
    attachMainComponent,
  };
};

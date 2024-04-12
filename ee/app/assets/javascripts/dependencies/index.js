import Vue from 'vue';
import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import DependenciesApp from './components/app.vue';
import createStore from './store';
import apolloProvider from './graphql/provider';
import { NAMESPACE_GROUP } from './constants';

export default (namespaceType) => {
  const el = document.querySelector('#js-dependencies-app');

  const {
    emptyStateSvgPath,
    documentationPath,
    endpoint,
    licensesEndpoint,
    exportEndpoint,
    vulnerabilitiesEndpoint,
    supportDocumentationPath,
    locationsEndpoint,
    belowGroupLimit,
    pageInfo,
  } = el.dataset;

  const store = createStore();

  const provide = {
    emptyStateSvgPath,
    documentationPath,
    endpoint,
    licensesEndpoint,
    exportEndpoint,
    vulnerabilitiesEndpoint,
    supportDocumentationPath,
    namespaceType,
    pageInfo: pageInfo ? convertObjectPropsToCamelCase(JSON.parse(pageInfo)) : {},
    belowGroupLimit: parseBoolean(belowGroupLimit),
  };

  if (namespaceType === NAMESPACE_GROUP) {
    provide.locationsEndpoint = locationsEndpoint;
  }

  return new Vue({
    el,
    name: 'DependenciesAppRoot',
    components: {
      DependenciesApp,
    },
    store,
    apolloProvider,
    provide,
    render(createElement) {
      return createElement(DependenciesApp);
    },
  });
};

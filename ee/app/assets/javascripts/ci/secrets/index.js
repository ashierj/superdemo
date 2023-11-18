import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { injectVueAppBreadcrumbs } from '~/lib/utils/breadcrumbs';
import {
  groupSecrets as mockGroupSecretsData,
  projectSecrets as mockProjectSecretsData,
} from 'ee_jest/ci/secrets/mock_data';
import getGroupSecretsQuery from './graphql/queries/client/get_group_secrets.query.graphql';
import getProjectSecretsQuery from './graphql/queries/client/get_project_secrets.query.graphql';
import createRouter from './router';

import GroupSecretsApp from './components/group_secrets_app.vue';
import ProjectSecretsApp from './components/project_secrets_app.vue';
import SecretsBreadcrumbs from './components/secrets_breadcrumbs.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

const initSecretsApp = (el, app, props, basePath) => {
  const router = createRouter(basePath);

  injectVueAppBreadcrumbs(router, SecretsBreadcrumbs);

  return new Vue({
    el,
    router,
    name: 'SecretsRoot',
    apolloProvider,
    render(createElement) {
      return createElement(app, { props });
    },
  });
};

export const initGroupSecretsApp = () => {
  const el = document.querySelector('#js-group-secrets-manager');

  if (!el) {
    return false;
  }

  const { groupPath, groupId, basePath } = el.dataset;

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: getGroupSecretsQuery,
    variables: { fullPath: groupPath },
    data: {
      group: {
        id: groupId,
        secrets: {
          nodes: mockGroupSecretsData,
        },
      },
    },
  });

  return initSecretsApp(el, GroupSecretsApp, { groupPath, groupId }, basePath);
};

export const initProjectSecretsApp = () => {
  const el = document.querySelector('#js-project-secrets-manager');

  if (!el) {
    return false;
  }

  const { projectPath, projectId, basePath } = el.dataset;

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: getProjectSecretsQuery,
    variables: { fullPath: projectPath },
    data: {
      project: {
        id: projectId,
        secrets: {
          nodes: mockProjectSecretsData,
        },
      },
    },
  });

  return initSecretsApp(el, ProjectSecretsApp, { projectPath, projectId }, basePath);
};

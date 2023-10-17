import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { injectVueAppBreadcrumbs } from '~/lib/utils/breadcrumbs';
import GroupSecretsApp from './group_secrets_app.vue';
import ProjectSecretsApp from './project_secrets_app.vue';
import createRouter from './router';
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

  return initSecretsApp(el, GroupSecretsApp, { groupPath, groupId }, basePath);
};

export const initProjectSecretsApp = () => {
  const el = document.querySelector('#js-project-secrets-manager');

  if (!el) {
    return false;
  }

  const { projectPath, projectId, basePath } = el.dataset;

  return initSecretsApp(el, ProjectSecretsApp, { projectPath, projectId }, basePath);
};

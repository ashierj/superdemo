import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import ListMemberRoles from './components/list_member_roles.vue';
import CustomRolesApp from './components/app.vue';

Vue.use(GlToast);
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initRolesAndPermissions = () => {
  const el = document.querySelector('#js-roles-and-permissions');

  if (!el) {
    return null;
  }

  const { groupFullPath } = el.dataset;

  return new Vue({
    el,
    name: 'RolesAndPermissionsRoot',
    apolloProvider,
    render(createElement) {
      return createElement(ListMemberRoles, {
        props: { groupFullPath },
      });
    },
  });
};

export const initCustomRolesApp = () => {
  const el = document.querySelector('#js-roles-and-permissions');

  if (!el) {
    return null;
  }

  const { documentationPath, emptyStateSvgPath, groupFullPath } = el.dataset;

  return new Vue({
    el,
    name: 'CustomRolesRoot',
    apolloProvider,
    provide: {
      documentationPath,
      emptyStateSvgPath,
      groupFullPath,
    },
    render(createElement) {
      return createElement(CustomRolesApp);
    },
  });
};

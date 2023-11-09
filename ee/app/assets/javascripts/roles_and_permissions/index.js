import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import RolesAndPermissions from './components/roles_and_permissions.vue';

Vue.use(GlToast);
Vue.use(VueApollo);

export const initRolesAndPermissions = ({ emptyText, showGroupSelector }) => {
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const el = document.querySelector('#js-roles-and-permissions');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    apolloProvider,
    name: 'RolesAndPermissionsRoot',
    render(h) {
      return h(RolesAndPermissions, {
        props: { groupId: el.dataset.groupId, emptyText, showGroupSelector },
      });
    },
  });
};

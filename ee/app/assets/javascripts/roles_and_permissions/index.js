import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import ListMemberRoles from './components/list_member_roles.vue';

Vue.use(GlToast);
Vue.use(VueApollo);

export const initRolesAndPermissions = () => {
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
      return h(ListMemberRoles, {
        props: { groupFullPath: el.dataset.groupFullPath },
      });
    },
  });
};

import Vue from 'vue';
import VueRouter from 'vue-router';
import { __, s__ } from '~/locale';
import {
  INDEX_ROUTE_NAME,
  NEW_ROUTE_NAME,
  DETAILS_ROUTE_NAME,
  AUDIT_LOG_ROUTE_NAME,
  EDIT_ROUTE_NAME,
} from './constants';
import SecretsTable from './components/secrets_table.vue';
import SecretFormWrapper from './components/secret_form_wrapper.vue';
import SecretTabs from './components/secret_tabs.vue';
import SecretDetails from './components/secret_details.vue';
import SecretAuditLog from './components/secret_audit_log.vue';

Vue.use(VueRouter);

export default (base) => {
  return new VueRouter({
    mode: 'history',
    base,
    routes: [
      {
        name: INDEX_ROUTE_NAME,
        path: '/',
        component: SecretsTable,
        meta: {
          getName: () => s__('Secrets|Secrets'),
          isRoot: true,
        },
      },
      {
        name: NEW_ROUTE_NAME,
        path: '/new',
        component: SecretFormWrapper,
        meta: {
          getName: () => s__('Secrets|New secret'),
        },
      },
      {
        path: '/:key',
        component: SecretTabs,
        children: [
          {
            name: DETAILS_ROUTE_NAME,
            path: 'details',
            component: SecretDetails,
            meta: {
              getName: ({ key }) => key,
              isDetails: true,
            },
          },
          {
            name: AUDIT_LOG_ROUTE_NAME,
            path: 'auditlog',
            component: SecretAuditLog,
            meta: {
              getName: () => s__('Secrets|Audit log'),
            },
          },
          {
            path: '',
            redirect: 'details',
          },
        ],
      },
      {
        name: EDIT_ROUTE_NAME,
        path: '/:key/edit',
        component: SecretFormWrapper,
        props: {
          isEditing: true,
        },
        meta: {
          getName: () => __('Edit'),
        },
      },
      {
        path: '*',
        redirect: '/',
      },
    ],
  });
};

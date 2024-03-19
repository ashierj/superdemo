import Vue from 'vue';
import VueRouter from 'vue-router';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SecretsTable from 'ee/ci/secrets/components/secrets_table/secrets_table.vue';
import SecretFormWrapper from 'ee/ci/secrets/components/secret_form/secret_form_wrapper.vue';
import SecretTabs from 'ee/ci/secrets/components/secret_details/secret_tabs.vue';
import SecretDetails from 'ee/ci/secrets/components/secret_details/secret_details.vue';
import SecretAuditLog from 'ee/ci/secrets/components/secret_details/secret_audit_log.vue';
import createRouter from 'ee/ci/secrets/router';
import ProjectSecretsApp from 'ee//ci/secrets/components/project_secrets_app.vue';
import GroupSecretsApp from 'ee//ci/secrets/components/group_secrets_app.vue';

Vue.use(VueRouter);

describe('Secrets router', () => {
  let wrapper;
  const base = '/-/secrets';
  const groupProps = {
    groupId: '1',
    groupPath: '/path/to/group',
  };

  const projectProps = {
    projectId: '2',
    projectPath: '/path/to/project',
  };

  const createSecretsApp = ({ route, app, props } = {}) => {
    const router = createRouter(base, props);
    if (route) {
      router.push(route);
    }

    wrapper = mountExtended(app, {
      router,
      propsData: { ...props },
      data() {
        return {
          secrets: [],
        };
      },
      mocks: {
        $apollo: {
          queries: {
            environments: { loading: true },
            secrets: { loading: false },
          },
        },
      },
    });
  };

  it.each`
    path               | componentNames                     | components
    ${'/'}             | ${'SecretsTable'}                  | ${[SecretsTable]}
    ${'/new'}          | ${'SecretFormWrapper'}             | ${[SecretFormWrapper]}
    ${'/key/details'}  | ${'SecretTabs and SecretDetails'}  | ${[SecretTabs, SecretDetails]}
    ${'/key/auditlog'} | ${'SecretTabs and SecretAuditLog'} | ${[SecretTabs, SecretAuditLog]}
    ${'/key/edit'}     | ${'SecretFormWrapper'}             | ${[SecretFormWrapper]}
  `('uses $componentNames for path "$path"', ({ path, components }) => {
    const router = createRouter(base, groupProps);

    expect(router.getMatchedComponents(path)).toStrictEqual(components);
  });

  it.each`
    path                   | redirect
    ${'/key'}              | ${'/key/details'}
    ${'/key/unknownroute'} | ${'/'}
  `('redirects from $path to $redirect', async ({ path, redirect }) => {
    const router = createRouter(base, groupProps);

    await router.push(path);

    expect(router.currentRoute.path).toBe(redirect);
  });

  describe.each`
    entity       | app                  | props           | fullPath
    ${'group'}   | ${GroupSecretsApp}   | ${groupProps}   | ${groupProps.groupPath}
    ${'project'} | ${ProjectSecretsApp} | ${projectProps} | ${projectProps.projectPath}
  `('$entity secrets form', ({ entity, app, props, fullPath }) => {
    it('provides the correct props when visiting the create form', () => {
      createSecretsApp({ route: '/new', app, props });

      expect(wrapper.findComponent(SecretFormWrapper).props()).toMatchObject({
        entity,
        fullPath,
      });
    });

    it('provides the correct props when visiting the edit form', () => {
      const route = { name: 'edit', params: { key: 'SECRET_KEY' } };
      createSecretsApp({ route, app, props });

      expect(wrapper.findComponent(SecretFormWrapper).props()).toMatchObject({
        entity,
        fullPath,
        isEditing: true,
        secretKey: 'SECRET_KEY',
      });
    });
  });
});

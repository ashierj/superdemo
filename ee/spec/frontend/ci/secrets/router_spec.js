import SecretsTable from 'ee/ci/secrets/components/secrets_table/secrets_table.vue';
import SecretFormWrapper from 'ee/ci/secrets/components/secret_form/secret_form_wrapper.vue';
import SecretTabs from 'ee/ci/secrets/components/secret_details/secret_tabs.vue';
import SecretDetails from 'ee/ci/secrets/components/secret_details/secret_details.vue';
import SecretAuditLog from 'ee/ci/secrets/components/secret_details/secret_audit_log.vue';
import createRouter from 'ee/ci/secrets/router';

describe('Secrets router', () => {
  const base = '/-/secrets';

  it.each`
    path               | componentNames                     | components
    ${'/'}             | ${'SecretsTable'}                  | ${[SecretsTable]}
    ${'/new'}          | ${'SecretFormWrapper'}             | ${[SecretFormWrapper]}
    ${'/key/details'}  | ${'SecretTabs and SecretDetails'}  | ${[SecretTabs, SecretDetails]}
    ${'/key/auditlog'} | ${'SecretTabs and SecretAuditLog'} | ${[SecretTabs, SecretAuditLog]}
    ${'/key/edit'}     | ${'SecretFormWrapper'}             | ${[SecretFormWrapper]}
  `('uses $componentNames for path "$path"', ({ path, components }) => {
    const router = createRouter(base);

    expect(router.getMatchedComponents(path)).toStrictEqual(components);
  });

  it.each`
    path                   | redirect
    ${'/key'}              | ${'/key/details'}
    ${'/key/unknownroute'} | ${'/'}
  `('redirects from $path to $redirect', async ({ path, redirect }) => {
    const router = createRouter(base);

    await router.push(path);

    expect(router.currentRoute.path).toBe(redirect);
  });
});

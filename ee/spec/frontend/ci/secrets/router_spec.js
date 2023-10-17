import SecretsTable from 'ee/ci/secrets/components/secrets_table.vue';
import SecretFormWrapper from 'ee/ci/secrets/components/secret_form_wrapper.vue';
import SecretTabs from 'ee/ci/secrets/components/secret_tabs.vue';
import SecretDetails from 'ee/ci/secrets/components/secret_details.vue';
import SecretAuditLog from 'ee/ci/secrets/components/secret_audit_log.vue';
import createRouter from 'ee/ci/secrets/router';

describe('Secrets router', () => {
  const base = '/-/secrets';

  it.each`
    path               | componentNames                     | components
    ${'/'}             | ${'SecretsTable'}                  | ${[SecretsTable]}
    ${'/new'}          | ${'SecretFormWrapper'}             | ${[SecretFormWrapper]}
    ${'/123/edit'}     | ${'SecretFormWrapper'}             | ${[SecretFormWrapper]}
    ${'/123/details'}  | ${'SecretTabs and SecretDetails'}  | ${[SecretTabs, SecretDetails]}
    ${'/123/auditlog'} | ${'SecretTabs and SecretAuditLog'} | ${[SecretTabs, SecretAuditLog]}
  `('uses $componentNames for path "$path"', ({ path, components }) => {
    const router = createRouter(base);

    expect(router.getMatchedComponents(path)).toStrictEqual(components);
  });
});

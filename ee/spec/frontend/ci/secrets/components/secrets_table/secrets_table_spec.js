import { GlTableLite } from '@gitlab/ui';
import { RouterLinkStub } from '@vue/test-utils';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { NEW_ROUTE_NAME, DETAILS_ROUTE_NAME } from 'ee/ci/secrets/constants';
import SecretsTable from 'ee/ci/secrets/components/secrets_table/secrets_table.vue';
import { projectSecrets } from '../../mock_data';

describe('SecretsTable component', () => {
  let wrapper;

  const findNewSecretButton = () => wrapper.findByTestId('new-secret-button');
  const findSecretsTable = () => wrapper.findComponent(GlTableLite);
  const findSecretDetailsLink = () => wrapper.findByTestId('secret-details-link');

  const defaultProps = { secrets: projectSecrets };

  const createComponent = (props = defaultProps) => {
    wrapper = mountExtended(SecretsTable, {
      propsData: {
        ...props,
      },
      stubs: {
        RouterLink: RouterLinkStub,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('shows a link to the new secret page', () => {
    expect(findNewSecretButton().attributes('to')).toBe(NEW_ROUTE_NAME);
  });

  it('renders a list of secrets and links to their details', () => {
    expect(findSecretsTable().exists()).toBe(true);
    expect(findSecretDetailsLink().props('to')).toMatchObject({
      name: DETAILS_ROUTE_NAME,
      params: { key: projectSecrets[0].key },
    });
  });
});

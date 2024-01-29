import { GlTableLite, GlLabel } from '@gitlab/ui';
import { RouterLinkStub } from '@vue/test-utils';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { NEW_ROUTE_NAME, DETAILS_ROUTE_NAME, EDIT_ROUTE_NAME } from 'ee/ci/secrets/constants';
import SecretsTable from 'ee/ci/secrets/components/secrets_table/secrets_table.vue';
import SecretActionsCell from 'ee/ci/secrets/components/secrets_table/secret_actions_cell.vue';
import { mockGroupSecretsData, mockProjectSecretsData } from 'ee/ci/secrets/mock_data';

describe('SecretsTable component', () => {
  let wrapper;

  const findNewSecretButton = () => wrapper.findByTestId('new-secret-button');
  const findSecretsTable = () => wrapper.findComponent(GlTableLite);
  const findSecretsTableRows = () => findSecretsTable().find('tbody').findAll('tr');
  const findSecretsCount = () => wrapper.findByTestId('secrets-count');
  const findSecretDetailsLink = () => wrapper.findByTestId('secret-details-link');
  const findSecretLabels = () => findSecretsTableRows().at(0).findAllComponents(GlLabel);
  const findSecretLastAccessed = () => wrapper.findByTestId('secret-last-accessed');
  const findSecretCreatedOn = () => wrapper.findByTestId('secret-created-on');
  const findSecretActionsCell = () => wrapper.findComponent(SecretActionsCell);

  const createComponent = (props) => {
    wrapper = mountExtended(SecretsTable, {
      propsData: {
        ...props,
      },
      stubs: {
        RouterLink: RouterLinkStub,
      },
    });
  };

  describe.each`
    scope        | secretsMockData
    ${'group'}   | ${mockGroupSecretsData}
    ${'project'} | ${mockProjectSecretsData}
  `('$scope secrets table', ({ secretsMockData }) => {
    const secret = secretsMockData[0];

    beforeEach(() => {
      createComponent({ secrets: secretsMockData });
    });

    it('shows a total count of secrets', () => {
      expect(findSecretsCount().text()).toBe(`${secretsMockData.length}`);
    });

    it('shows a link to the new secret page', () => {
      expect(findNewSecretButton().attributes('to')).toBe(NEW_ROUTE_NAME);
    });

    it('renders a table of secrets', () => {
      expect(findSecretsTable().exists()).toBe(true);
      expect(findSecretsTableRows().length).toBe(secretsMockData.length);
    });

    it('shows the secret name as a link to the secret details', () => {
      expect(findSecretDetailsLink().text()).toBe(secret.name);
      expect(findSecretDetailsLink().props('to')).toMatchObject({
        name: DETAILS_ROUTE_NAME,
        params: { key: secret.key },
      });
    });

    it.each([0, 1])('shows the labels for a secret', (labelIndex) => {
      expect(findSecretLabels().at(labelIndex).props()).toMatchObject({
        title: secret.labels[labelIndex].title,
        backgroundColor: secret.labels[labelIndex].color,
      });
    });

    it('shows when the secret was last accessed', () => {
      expect(findSecretLastAccessed().props('time')).toBe(secret.lastAccessed);
    });

    it('shows when the secret was created', () => {
      expect(findSecretCreatedOn().props('date')).toBe(secret.createdOn);
    });

    it('passes correct props to actions cell', () => {
      expect(findSecretActionsCell().props()).toMatchObject({
        detailsRoute: {
          name: EDIT_ROUTE_NAME,
          params: { key: secret.key },
        },
      });
    });
  });
});

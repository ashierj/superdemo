import Vue from 'vue';
import VueApollo from 'vue-apollo';
import CompanyInformation from 'ee/vue_shared/purchase_flow/components/company_information.vue';
import { mockBillingAccount } from 'ee_jest/subscriptions/mock_data';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { logError } from '~/lib/logger';
import { CUSTOMERSDOT_CLIENT } from 'ee/subscriptions/buy_addons_shared/constants';
import createMockApollo, { createMockClient } from 'helpers/mock_apollo_helper';
import getBillingAccountQuery from 'ee/vue_shared/purchase_flow/graphql/queries/get_billing_account.customer.query.graphql';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

Vue.use(VueApollo);
jest.mock('~/lib/logger');

describe('Company information', () => {
  let wrapper;
  let apolloProvider;

  const mockBillingAccountWithoutTaxId = { ...mockBillingAccount, vatFieldVisible: false };

  const createComponent = async (
    billingAccountFn = jest
      .fn()
      .mockResolvedValue({ data: { billingAccount: mockBillingAccount } }),
  ) => {
    apolloProvider = createMockApollo();

    apolloProvider.clients[CUSTOMERSDOT_CLIENT] = createMockClient([
      [getBillingAccountQuery, billingAccountFn],
    ]);

    wrapper = shallowMountExtended(CompanyInformation, {
      apolloProvider,
    });
    await waitForPromises();
  };

  const findCompanyInformationContent = () =>
    wrapper.findByTestId('billing-account-company-wrapper');
  const findTitle = () => wrapper.find('h6');
  const findCompanyName = () => wrapper.findByTestId('billing-account-company-name');
  const findCompanyTaxId = () => wrapper.findByTestId('billing-account-tax-id');

  describe('when getBillingAccountQuery returns a valid billing account', () => {
    describe.each`
      testCaseName        | billingAccount                    | showsTaxId
      ${'with tax ID'}    | ${mockBillingAccount}             | ${true}
      ${'without tax ID'} | ${mockBillingAccountWithoutTaxId} | ${false}
    `('$testCaseName', ({ billingAccount, showsTaxId }) => {
      beforeEach(async () => {
        gon.features = { keyContactsManagement: true };

        await createComponent(jest.fn().mockResolvedValue({ data: { billingAccount } }));
      });

      it('shows company information content', () => {
        expect(findCompanyInformationContent().exists()).toBe(true);
      });

      it('shows title', () => {
        expect(findTitle().exists()).toBe(true);
      });

      it('shows company name', () => {
        expect(findCompanyName().exists()).toBe(true);
      });

      it(`${showsTaxId ? 'shows' : 'does not show'} company tax ID`, () => {
        expect(findCompanyTaxId().exists()).toBe(showsTaxId);
      });
    });
  });

  describe('when getBillingAccountQuery does not return a valid billing account', () => {
    beforeEach(async () => {
      gon.features = { keyContactsManagement: true };
      await createComponent(jest.fn().mockResolvedValue({ data: { billingAccount: null } }));
    });

    it('does not show company information content', () => {
      expect(findCompanyInformationContent().exists()).toBe(false);
    });
  });

  describe('when keyContactsManagement flag is false', () => {
    beforeEach(async () => {
      gon.features = { keyContactsManagement: false };
      await createComponent();
    });

    it('does not show company information content', () => {
      expect(findCompanyInformationContent().exists()).toBe(false);
    });
  });

  describe('when getBillingAccountQuery responds with error', () => {
    const error = new Error('oh no!');

    beforeEach(async () => {
      gon.features = { keyContactsManagement: true };
      jest.spyOn(Sentry, 'captureException');

      await createComponent(jest.fn().mockRejectedValue(error));
      await waitForPromises();
    });

    it('logs to Sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });

    it('logs the error to console', () => {
      expect(logError).toHaveBeenCalledWith(error);
    });

    it('does not show company information content', () => {
      expect(findCompanyInformationContent().exists()).toBe(false);
    });
  });
});

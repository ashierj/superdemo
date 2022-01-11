import { GlEmptyState, GlAlert } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { pick } from 'lodash';
import {
  I18N_STORAGE_PRODUCT_LABEL,
  I18N_STORAGE_PRODUCT_UNIT,
  I18N_DETAILS_FORMULA,
  I18N_STORAGE_FORMULA_TOTAL,
  I18N_DETAILS_FORMULA_WITH_ALERT,
  i18nStorageSummaryTitle,
  I18N_STORAGE_SUMMARY_TOTAL,
  I18N_STORAGE_TITLE,
  I18N_STORAGE_PRICE_PER_UNIT,
  I18N_STORAGE_TOOLTIP_NOTE,
  I18N_API_ERROR,
  planTags,
  STORAGE_PER_PACK,
} from 'ee/subscriptions/buy_addons_shared/constants';
import Checkout from 'ee/subscriptions/buy_addons_shared/components/checkout.vue';
import AddonPurchaseDetails from 'ee/subscriptions/buy_addons_shared/components/checkout/addon_purchase_details.vue';
import OrderSummary from 'ee/subscriptions/buy_addons_shared/components/order_summary.vue';
import SummaryDetails from 'ee/subscriptions/buy_addons_shared/components/order_summary/summary_details.vue';
import App from 'ee/subscriptions/buy_addons_shared/components/app.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createMockApolloProvider } from 'ee_jest/subscriptions/spec_helper';
import { mockStoragePlans } from 'ee_jest/subscriptions/mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Buy Storage App', () => {
  let wrapper;

  function createComponent(apolloProvider) {
    wrapper = shallowMountExtended(App, {
      localVue,
      apolloProvider,
      propsData: {
        config: {
          alertText: '',
          formula: I18N_DETAILS_FORMULA,
          formulaWithAlert: I18N_DETAILS_FORMULA_WITH_ALERT,
          formulaTotal: I18N_STORAGE_FORMULA_TOTAL,
          hasExpiration: true,
          pricePerUnit: I18N_STORAGE_PRICE_PER_UNIT,
          productLabel: I18N_STORAGE_PRODUCT_LABEL,
          productUnit: I18N_STORAGE_PRODUCT_UNIT,
          quantityPerPack: STORAGE_PER_PACK,
          summaryTitle: i18nStorageSummaryTitle,
          summaryTotal: I18N_STORAGE_SUMMARY_TOTAL,
          title: I18N_STORAGE_TITLE,
          tooltipNote: I18N_STORAGE_TOOLTIP_NOTE,
        },
        tags: [planTags.STORAGE_PLAN],
      },
      stubs: {
        Checkout,
        AddonPurchaseDetails,
        OrderSummary,
        SummaryDetails,
      },
    });
    return waitForPromises();
  }

  const getStoragePlan = () => pick(mockStoragePlans[0], ['id', 'code', 'pricePerYear', 'name']);
  const findCheckout = () => wrapper.findComponent(Checkout);
  const findOrderSummary = () => wrapper.findComponent(OrderSummary);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findPriceLabel = () => wrapper.findByTestId('price-per-unit');
  const findQuantityText = () => wrapper.findByTestId('addon-quantity-text');
  const findRootElement = () => wrapper.findByTestId('buy-addons-shared');
  const findSummaryLabel = () => wrapper.findByTestId('summary-label');
  const findSummaryTotal = () => wrapper.findByTestId('summary-total');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when data is received', () => {
    beforeEach(() => {
      const mockApollo = createMockApolloProvider();
      return createComponent(mockApollo);
    });

    it('should display the root element', () => {
      expect(findRootElement().exists()).toBe(true);
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(false);
    });

    it('provides the correct props to checkout', () => {
      expect(findCheckout().props()).toMatchObject({
        plan: { ...getStoragePlan, isAddon: true },
      });
    });

    it('provides the correct props to order summary', () => {
      expect(findOrderSummary().props()).toMatchObject({
        plan: { ...getStoragePlan, isAddon: true },
        title: I18N_STORAGE_TITLE,
      });
    });

    describe('and an error occurred', () => {
      beforeEach(() => {
        findOrderSummary().vm.$emit('alertError', I18N_API_ERROR);
      });

      it('shows the alert', () => {
        expect(findAlert().props()).toMatchObject({
          dismissible: false,
          variant: 'danger',
        });
        expect(findAlert().text()).toBe(I18N_API_ERROR);
      });
    });
  });

  describe('when data is not received', () => {
    it('should display the GlEmptyState for empty data', async () => {
      const mockApollo = createMockApolloProvider({
        plansQueryMock: jest.fn().mockResolvedValue({ data: null }),
      });
      await createComponent(mockApollo);

      expect(findRootElement().exists()).toBe(false);
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });

    it('should display the GlEmptyState for empty plans', async () => {
      const mockApollo = createMockApolloProvider({
        plansQueryMock: jest.fn().mockResolvedValue({ data: { plans: null } }),
      });
      await createComponent(mockApollo);

      expect(findRootElement().exists()).toBe(false);
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });

    it('should display the GlEmptyState for plans data of wrong type', async () => {
      const mockApollo = createMockApolloProvider({
        plansQueryMock: jest.fn().mockResolvedValue({ data: { plans: {} } }),
      });
      await createComponent(mockApollo);

      expect(findRootElement().exists()).toBe(false);
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });
  });

  describe('when an error is received', () => {
    it('should display the GlEmptyState', async () => {
      const mockApollo = createMockApolloProvider({
        plansQueryMock: jest.fn().mockRejectedValue(new Error('An error happened!')),
      });
      await createComponent(mockApollo);

      expect(findRootElement().exists()).toBe(false);
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });
  });

  describe('labels', () => {
    it('shows labels correctly for 1 pack', async () => {
      const mockApollo = createMockApolloProvider({
        plansQueryMock: jest.fn().mockResolvedValue({ data: { plans: mockStoragePlans } }),
      });
      await createComponent(mockApollo);

      expect(findQuantityText().text()).toMatchInterpolatedText(
        'x 10 GB per pack = 10 GB of storage',
      );
      expect(findSummaryLabel().text()).toBe('1 storage pack');
      expect(findSummaryTotal().text()).toBe('Total storage: 10 GB');
      expect(findPriceLabel().text()).toBe('$60 per 10 GB storage pack per year');
    });

    it('shows labels correctly for 2 packs', async () => {
      const mockApollo = createMockApolloProvider({}, { quantity: 2 });
      await createComponent(mockApollo);

      expect(findQuantityText().text()).toMatchInterpolatedText(
        'x 10 GB per pack = 20 GB of storage',
      );
      expect(findSummaryLabel().text()).toBe('2 storage packs');
      expect(findSummaryTotal().text()).toBe('Total storage: 20 GB');
    });

    it('does not show labels if input is invalid', async () => {
      const mockApollo = createMockApolloProvider({}, { quantity: -1 });
      await createComponent(mockApollo);

      expect(findQuantityText().text()).toMatchInterpolatedText('x 10 GB per pack');
    });
  });
});

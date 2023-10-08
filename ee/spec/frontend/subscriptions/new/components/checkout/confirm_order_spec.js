import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import Api from 'ee/api';
import { STEPS } from 'ee/subscriptions/constants';
import ConfirmOrder from 'ee/subscriptions/new/components/checkout/confirm_order.vue';
import { createMockApolloProvider } from 'ee_jest/vue_shared/purchase_flow/spec_helper';
import * as googleTagManager from '~/google_tag_manager';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import Tracking from '~/tracking';
import { ActiveModelError } from '~/lib/utils/error_utils';

jest.mock('~/alert');

describe('Confirm Order', () => {
  Vue.use(Vuex);
  Vue.use(VueApollo);

  let wrapper;
  let store;

  jest.mock('ee/api.js');

  const hasValidPriceDetailsMock = jest.fn();

  const mockConfirmOrderParams = {
    setup_for_company: false,
    selected_group: 123,
    new_user: false,
    customer: {
      country: 'USA',
      address_1: 'Address Line One',
      address_2: 'Address Line Two',
      city: 'San Francisco',
      state: 'California',
      zip_code: '1234',
      company: 'Org',
    },
    subscription: {
      plan_id: 'bronze_plan_id',
      payment_method_id: '123',
      quantity: 1,
      source: 'Source',
    },
  };

  const mockSelectedPlanDetails = {
    value: 'bronze_plan_id',
    text: 'Bronze Plan',
    code: 'bronze',
    isEligibleToUsePromoCode: false,
  };

  const createStore = () => {
    return new Vuex.Store({
      getters: {
        confirmOrderParams: () => mockConfirmOrderParams,
        selectedPlanDetails: () => mockSelectedPlanDetails,
        hasValidPriceDetails: hasValidPriceDetailsMock,
        totalExVat: () => 110,
        vat: () => 10,
      },
    });
  };

  function createComponent(options = {}) {
    store = createStore();
    return shallowMount(ConfirmOrder, {
      store,
      ...options,
    });
  }

  const findConfirmButton = () => wrapper.findComponent(GlButton);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  describe('Active', () => {
    describe('when receiving proper step data', () => {
      beforeEach(() => {
        const mockApolloProvider = createMockApolloProvider(STEPS, 3);
        wrapper = createComponent({ apolloProvider: mockApolloProvider });
      });

      it('button should be visible', () => {
        expect(findConfirmButton().exists()).toBe(true);
      });

      it('shows the text "Confirm purchase"', () => {
        expect(findConfirmButton().text()).toBe('Confirm purchase');
      });

      it('the loading indicator should not be visible', () => {
        expect(findLoadingIcon().exists()).toBe(false);
      });
    });

    describe('Clicking the button', () => {
      beforeEach(() => {
        const mockApolloProvider = createMockApolloProvider(STEPS, 3);
        wrapper = createComponent({ apolloProvider: mockApolloProvider });
        Api.confirmOrder = jest.fn().mockReturnValue(new Promise(jest.fn()));

        findConfirmButton().vm.$emit('click');
      });

      it('calls the confirmOrder API method', () => {
        expect(Api.confirmOrder).toHaveBeenCalledWith(mockConfirmOrderParams);
      });

      it('shows the text "Confirming..."', () => {
        expect(findConfirmButton().text()).toBe('Confirming...');
      });

      it('the loading indicator should be visible', () => {
        expect(findLoadingIcon().exists()).toBe(true);
      });

      it('button should be disabled', async () => {
        await nextTick();

        expect(findConfirmButton().attributes('disabled')).toBeDefined();
      });
    });

    describe('On confirm order success', () => {
      let trackTransactionSpy;
      let trackingSpy;

      beforeEach(() => {
        useMockLocationHelper();
        trackingSpy = jest.spyOn(Tracking, 'event');
        trackTransactionSpy = jest.spyOn(googleTagManager, 'trackTransaction');

        const mockApolloProvider = createMockApolloProvider(STEPS, 3);
        wrapper = createComponent({ apolloProvider: mockApolloProvider });

        Api.confirmOrder = jest
          .fn()
          .mockReturnValue(Promise.resolve({ data: { location: 'https://new-location.com' } }));

        findConfirmButton().vm.$emit('click');
      });

      afterEach(() => {
        trackingSpy.mockRestore();
        trackTransactionSpy.mockRestore();
      });

      it('calls trackTransaction', () => {
        expect(trackTransactionSpy).toHaveBeenCalledWith({
          paymentOption: '123',
          revenue: 110,
          tax: 10,
          selectedPlan: 'bronze_plan_id',
          quantity: 1,
        });
      });

      it('calls tracking event', () => {
        expect(trackingSpy).toHaveBeenCalledWith('default', 'click_button', {
          label: 'confirm_purchase',
          property: 'Success: subscription',
        });
      });

      it('redirects to appropriate location', () => {
        expect(window.location.assign).toHaveBeenCalledWith('https://new-location.com');
      });
    });

    describe('On confirm order error', () => {
      let trackingSpy;

      beforeEach(() => {
        trackingSpy = jest.spyOn(Tracking, 'event');

        const mockApolloProvider = createMockApolloProvider(STEPS, 3);
        wrapper = createComponent({ apolloProvider: mockApolloProvider });
      });

      describe('when response has name', () => {
        beforeEach(() => {
          Api.confirmOrder = jest
            .fn()
            .mockReturnValue(Promise.resolve({ data: { name: ['Error_1', "Error ' 2"] } }));
          findConfirmButton().vm.$emit('click');
        });

        it('emits error event with appropriate error', () => {
          expect(wrapper.emitted('error')).toEqual([
            [new ActiveModelError(null, '"Name: Error_1, Error \' 2"')],
          ]);
        });

        it('calls tracking event', () => {
          expect(trackingSpy).toHaveBeenCalledWith('default', 'click_button', {
            label: 'confirm_purchase',
            property: "Name: Error_1, Error ' 2",
          });
        });
      });

      describe('when response has non promo code related errors', () => {
        const errors = 'Errorororor';
        beforeEach(() => {
          Api.confirmOrder = jest.fn().mockReturnValue(Promise.resolve({ data: { errors } }));
          findConfirmButton().vm.$emit('click');
        });

        it('emits error event with appropriate error', () => {
          expect(wrapper.emitted('error')).toEqual([[new ActiveModelError(null, `"${errors}"`)]]);
        });

        it('calls tracking event', () => {
          expect(trackingSpy).toHaveBeenCalledWith('default', 'click_button', {
            label: 'confirm_purchase',
            property: errors,
          });
        });
      });

      describe('when response has promo code errors', () => {
        const errors = {
          message: 'Promo code is invalid',
          attributes: ['promo_code'],
          code: 'INVALID',
        };
        beforeEach(() => {
          Api.confirmOrder = jest.fn().mockReturnValue(Promise.resolve({ data: { errors } }));
          findConfirmButton().vm.$emit('click');
        });

        it('emits error event with appropriate error', () => {
          expect(wrapper.emitted('error')).toEqual([
            [new ActiveModelError(null, '"Promo code is invalid"')],
          ]);
        });

        it('calls tracking event', () => {
          expect(trackingSpy).toHaveBeenCalledWith('default', 'click_button', {
            label: 'confirm_purchase',
            property: 'Promo code is invalid',
          });
        });
      });

      describe('when response has error attribute map', () => {
        const errors = { email: ["can't be blank"] };
        const errorAttributeMap = { email: ['taken'] };

        beforeEach(() => {
          Api.confirmOrder = jest
            .fn()
            .mockReturnValue(
              Promise.resolve({ data: { errors, error_attribute_map: errorAttributeMap } }),
            );
          findConfirmButton().vm.$emit('click');
        });

        it('emits error event with appropriate error', () => {
          expect(wrapper.emitted('error')).toEqual([
            [new ActiveModelError(errorAttributeMap, JSON.stringify(errors))],
          ]);
        });

        it('calls tracking event', () => {
          expect(trackingSpy).toHaveBeenCalledWith('default', 'click_button', {
            label: 'confirm_purchase',
            property: errors,
          });
        });
      });

      afterEach(() => {
        trackingSpy.mockRestore();
      });
    });

    describe('On confirm order failure', () => {
      let trackingSpy;
      const error = new Error('Request failed with status code 500');

      useMockLocationHelper();

      beforeEach(() => {
        trackingSpy = jest.spyOn(Tracking, 'event');

        const mockApolloProvider = createMockApolloProvider(STEPS, 3);
        wrapper = createComponent({ apolloProvider: mockApolloProvider });

        Api.confirmOrder = jest.fn().mockRejectedValue(error);

        findConfirmButton().vm.$emit('click');
      });

      it('calls tracking event', () => {
        expect(trackingSpy).toHaveBeenCalledWith('default', 'click_button', {
          label: 'confirm_purchase',
          property: 'Request failed with status code 500',
        });
      });

      it('emits error event', () => {
        expect(wrapper.emitted('error')).toEqual([[error]]);
      });

      afterEach(() => {
        trackingSpy.mockRestore();
      });
    });

    describe('Button state', () => {
      const mockApolloProvider = createMockApolloProvider(STEPS, 3);

      it('should be enabled when not confirming and has valid price details', async () => {
        hasValidPriceDetailsMock.mockReturnValue(true);

        wrapper = createComponent({ apolloProvider: mockApolloProvider });
        await nextTick();

        expect(findConfirmButton().attributes('disabled')).toBe(undefined);
      });

      it('should be disabled when confirming and has valid price details', async () => {
        hasValidPriceDetailsMock.mockReturnValue(true);
        // Return unresolved promise to simulate loading state
        Api.confirmOrder = jest.fn().mockReturnValue(new Promise(() => {}));
        wrapper = createComponent({ apolloProvider: mockApolloProvider });

        findConfirmButton().vm.$emit('click');
        await nextTick();

        expect(findConfirmButton().attributes('disabled')).toBeDefined();
      });

      it('should be disabled when not confirming and has invalid price details', async () => {
        hasValidPriceDetailsMock.mockReturnValue(false);

        wrapper = createComponent({ apolloProvider: mockApolloProvider });
        await nextTick();

        expect(findConfirmButton().attributes('disabled')).toBeDefined();
      });
    });
  });

  describe('Inactive', () => {
    beforeEach(() => {
      const mockApolloProvider = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ apolloProvider: mockApolloProvider });
    });

    it('button should not be visible', () => {
      expect(findConfirmButton().exists()).toBe(false);
    });
  });
});

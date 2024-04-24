import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import Component from 'ee/subscriptions/new/components/checkout/zuora.vue';
import { getStoreConfig } from 'ee/subscriptions/new/store';
import * as types from 'ee/subscriptions/new/store/mutation_types';
import { mockTracking } from 'helpers/tracking_helper';

describe('Zuora', () => {
  Vue.use(Vuex);

  let store;
  let wrapper;
  let trackingSpy;

  const actionMocks = {
    startLoadingZuoraScript: jest.fn(),
    fetchPaymentFormParams: jest.fn(),
    zuoraIframeRendered: jest.fn(),
    paymentFormSubmitted: jest.fn(),
  };

  const createComponent = (props = {}) => {
    const { actions, ...storeConfig } = getStoreConfig();
    store = new Vuex.Store({
      ...storeConfig,
      actions: {
        ...actions,
        ...actionMocks,
      },
    });

    wrapper = shallowMount(Component, {
      propsData: {
        active: true,
        ...props,
      },
      store,
    });

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };

  const findLoading = () => wrapper.findComponent(GlLoadingIcon);
  const findZuoraPayment = () => wrapper.find('#zuora_payment');

  beforeEach(() => {
    window.Z = {
      runAfterRender(fn) {
        return Promise.resolve().then(fn);
      },
      renderWithErrorHandler() {},
    };
  });

  afterEach(() => {
    delete window.Z;
  });

  describe('mounted', () => {
    it('starts loading zuora script', () => {
      createComponent();

      expect(actionMocks.startLoadingZuoraScript).toHaveBeenCalled();
    });
  });

  describe('when active', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not show the loading icon', () => {
      expect(findLoading().exists()).toBe(false);
    });

    it('the zuora_payment selector should be visible', () => {
      expect(findZuoraPayment().element.style.display).toEqual('');
    });

    describe('when toggling the loading indicator', () => {
      beforeEach(async () => {
        store.commit(types.UPDATE_IS_LOADING_PAYMENT_METHOD, true);

        await nextTick();
      });

      it('shows the loading icon', () => {
        expect(findLoading().exists()).toBe(true);
      });

      it('the zuora_payment selector should not be visible', () => {
        expect(findZuoraPayment().element.style.display).toEqual('none');
      });
    });
  });

  describe('when not active', () => {
    beforeEach(() => {
      createComponent({ active: false });
    });

    it('does not show loading icon', () => {
      expect(findLoading().exists()).toBe(false);
    });

    it('the zuora_payment selector should not be visible', () => {
      expect(findZuoraPayment().element.style.display).toEqual('none');
    });
  });

  describe('when rendering', () => {
    beforeEach(async () => {
      createComponent();
      store.commit(types.UPDATE_PAYMENT_FORM_PARAMS, {});
      await nextTick();
    });

    it('renderZuoraIframe is called when the paymentFormParams are updated', () => {
      expect(actionMocks.zuoraIframeRendered).toHaveBeenCalled();
      wrapper.vm.handleZuoraCallback();
      expect(actionMocks.paymentFormSubmitted).toHaveBeenCalled();
    });

    it('tracks frame_loaded event', () => {
      expect(trackingSpy).toHaveBeenCalledWith('Zuora_cc', 'iframe_loaded', {
        category: 'Zuora_cc',
      });
    });
  });

  describe('Zuora form', () => {
    describe('when successful', () => {
      beforeEach(async () => {
        createComponent();

        wrapper.vm.handleZuoraCallback({ success: 'true' });
        await nextTick();
      });

      it('emits success event on correct response for tracking', () => {
        expect(wrapper.emitted().success.length).toEqual(1);
      });
    });

    describe('with an error when setting up Zuora iframe', () => {
      beforeEach(async () => {
        createComponent();

        wrapper.vm.handleZuoraCallback({
          errorCode: 'Invalid_Security',
          errorMessage:
            'Request with protocol [http://localhost:3000] is not allowed for page xyz[https://localhost:3001]',
        });
        await nextTick();
      });

      it('emits error with message for tracking', () => {
        expect(wrapper.emitted().error.length).toEqual(1);
        expect(wrapper.emitted().error[0]).toEqual([
          'Request with protocol [http://localhost:3000] is not allowed for page xyz[https://localhost:3001]',
        ]);
      });

      it('tracks Zuora error', () => {
        expect(trackingSpy).toHaveBeenCalledWith('Zuora_cc', 'error', {
          label: 'payment_form_submitted',
          property:
            'Request with protocol [http://localhost:3000] is not allowed for page xyz[https://localhost:3001]',
          category: 'Zuora_cc',
        });
      });
    });

    describe('with an error when submitting a credit card', () => {
      beforeEach(() => {
        createComponent();
      });

      describe('with a message with a known error code', () => {
        beforeEach(async () => {
          wrapper.vm.handleErrorMessage(
            null,
            'unknown',
            '[GatewayTransactionError] Transaction declined.402 - [card_error/authentication_required/authentication_required] Your card was declined. This transaction requires authentication.',
          );
          await nextTick();
        });

        it('submits payment form action with error details', () => {
          expect(actionMocks.paymentFormSubmitted).toHaveBeenCalledWith(expect.any(Object), {
            errorMessage:
              '[GatewayTransactionError] Transaction declined.402 - [card_error/authentication_required/authentication_required] Your card was declined. This transaction requires authentication.',
            errorCode: '[card_error/authentication_required/authentication_required]',
          });
        });

        it('emits error with message for tracking', () => {
          expect(wrapper.emitted().error.length).toEqual(1);
          expect(wrapper.emitted().error[0]).toEqual([
            '[GatewayTransactionError] Transaction declined.402 - [card_error/authentication_required/authentication_required] Your card was declined. This transaction requires authentication.',
          ]);
        });

        it('tracks Zuora error', () => {
          expect(trackingSpy).toHaveBeenCalledWith('Zuora_cc', 'error', {
            label: 'payment_form_submitted',
            property:
              '[GatewayTransactionError] Transaction declined.402 - [card_error/authentication_required/authentication_required] Your card was declined. This transaction requires authentication.',
            category: 'Zuora_cc',
          });
        });
      });

      describe('with an unknown error type', () => {
        beforeEach(async () => {
          wrapper.vm.handleErrorMessage(null, 'unknown', 'An error occured');
          await nextTick();
        });

        it('submits payment form action with error details', () => {
          expect(actionMocks.paymentFormSubmitted).toHaveBeenCalledWith(expect.any(Object), {
            errorMessage: 'An error occured',
            errorCode: 'unknown',
          });
        });

        it('emits error with message for tracking', () => {
          expect(wrapper.emitted().error.length).toEqual(1);
          expect(wrapper.emitted().error[0]).toEqual(['An error occured']);
        });

        it('tracks Zuora error', () => {
          expect(trackingSpy).toHaveBeenCalledWith('Zuora_cc', 'error', {
            label: 'payment_form_submitted',
            property: 'An error occured',
            category: 'Zuora_cc',
          });
        });
      });
    });
  });
});

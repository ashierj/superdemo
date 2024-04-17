import { GlModal, GlFormTextarea } from '@gitlab/ui';
import { kebabCase, pick } from 'lodash';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { sprintf } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import HandRaiseLeadModal from 'ee/hand_raise_leads/hand_raise_lead/components/hand_raise_lead_modal.vue';
import CountryOrRegionSelector from 'ee/trials/components/country_or_region_selector.vue';
import {
  PQL_MODAL_PRIMARY,
  PQL_MODAL_CANCEL,
  PQL_MODAL_HEADER_TEXT,
  PQL_MODAL_FOOTER_TEXT,
} from 'ee/hand_raise_leads/hand_raise_lead/constants';
import * as SubscriptionsApi from 'ee/api/subscriptions_api';
import { FORM_DATA, USER, CREATE_HAND_RAISE_LEAD_PATH } from './mock_data';

Vue.use(VueApollo);

describe('HandRaiseLeadModal', () => {
  let wrapper;
  let trackingSpy;
  const ctaTracking = {};

  const createComponent = (props = {}) => {
    return shallowMountExtended(HandRaiseLeadModal, {
      propsData: {
        small: false,
        submitPath: CREATE_HAND_RAISE_LEAD_PATH,
        user: USER,
        ctaTracking,
        modalId: 'hand-raise-lead-modal',
        ...props,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findFormInput = (testId) => wrapper.findByTestId(testId);
  const findCountryOrRegionSelector = () => wrapper.findComponent(CountryOrRegionSelector);
  const submitForm = () => findModal().vm.$emit('primary');

  const fillForm = ({ stateRequired = false, comment = '' } = {}) => {
    const { country, state } = FORM_DATA;
    const inputForms = pick(FORM_DATA, [
      'firstName',
      'lastName',
      'companyName',
      'companySize',
      'phoneNumber',
    ]);

    Object.entries(inputForms).forEach(([key, value]) => {
      wrapper.findByTestId(kebabCase(key)).vm.$emit('input', value);
    });

    findCountryOrRegionSelector().vm.$emit('change', {
      country,
      state,
      stateRequired,
    });

    wrapper.findComponent(GlFormTextarea).vm.$emit('input', comment);

    return nextTick();
  };

  describe('rendering', () => {
    beforeEach(() => {
      wrapper = createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    it('has the default injected values', () => {
      const formInputValues = [
        { id: 'first-name', value: 'Joe' },
        { id: 'last-name', value: 'Doe' },
        { id: 'company-name', value: 'ACME' },
        { id: 'phone-number', value: '' },
        { id: 'company-size', value: undefined },
      ];

      formInputValues.forEach(({ id, value }) => {
        expect(findFormInput(id).attributes('value')).toBe(value);
      });

      expect(findFormInput('state').exists()).toBe(false);
    });

    it('has the correct form input in the form content', () => {
      const visibleFields = [
        'first-name',
        'last-name',
        'company-name',
        'company-size',
        'phone-number',
      ];

      visibleFields.forEach((f) => expect(wrapper.findByTestId(f).exists()).toBe(true));

      expect(wrapper.findByTestId('state').exists()).toBe(false);
    });

    it('has the correct text in the modal content', () => {
      expect(findModal().text()).toContain(sprintf(PQL_MODAL_HEADER_TEXT, { userName: 'joe' }));
      expect(findModal().text()).toContain(PQL_MODAL_FOOTER_TEXT);
    });

    it('has the correct modal props', () => {
      expect(findModal().props('actionPrimary')).toStrictEqual({
        text: PQL_MODAL_PRIMARY,
        attributes: { variant: 'confirm', disabled: true },
      });
      expect(findModal().props('actionCancel')).toStrictEqual({
        text: PQL_MODAL_CANCEL,
      });
    });

    it('tracks modal view', async () => {
      await findModal().vm.$emit('change');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'hand_raise_form_viewed', {
        label: 'hand_raise_lead_form',
      });
    });
  });

  describe('submit button', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('becomes enabled when required info is there', async () => {
      await fillForm();

      expect(findModal().props('actionPrimary')).toStrictEqual({
        text: PQL_MODAL_PRIMARY,
        attributes: { variant: 'confirm', disabled: false },
      });
    });
  });

  describe('form', () => {
    beforeEach(async () => {
      wrapper = createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      await fillForm({ stateRequired: true, comment: 'comment' });
    });

    describe('emits loading status change', () => {
      beforeEach(() => {
        jest.spyOn(SubscriptionsApi, 'sendHandRaiseLead').mockResolvedValue();
      });

      it('emits loading status change', async () => {
        await submitForm();

        expect(wrapper.emitted('loading')).toEqual([[true]]);

        await waitForPromises();

        expect(wrapper.emitted('loading')[1]).toEqual([false]);
      });
    });

    describe('successful submission', () => {
      beforeEach(() => {
        jest.spyOn(SubscriptionsApi, 'sendHandRaiseLead').mockResolvedValue();

        submitForm();
      });

      it('primary submits the valid form', () => {
        expect(SubscriptionsApi.sendHandRaiseLead).toHaveBeenCalledWith(
          '/-/subscriptions/hand_raise_leads',
          {
            namespaceId: 1,
            comment: 'comment',
            glmContent: 'some-content',
            productInteraction: '_product_interaction_',
            ...FORM_DATA,
          },
        );
      });

      it('clears the form after submission', () => {
        ['first-name', 'last-name', 'company-name', 'phone-number'].forEach((f) =>
          expect(wrapper.findByTestId(f).attributes('value')).toBe(''),
        );

        expect(wrapper.findByTestId('company-size').attributes('value')).toBe(undefined);
        expect(findCountryOrRegionSelector().props()).toMatchObject({
          country: '',
          state: '',
          required: false,
        });
      });

      it('tracks successful submission', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'hand_raise_submit_form_succeeded', {
          label: 'hand_raise_lead_form',
        });
      });
    });

    describe('failed submission', () => {
      beforeEach(() => {
        jest.spyOn(SubscriptionsApi, 'sendHandRaiseLead').mockRejectedValue();

        submitForm();
      });

      it('tracks failed submission', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'hand_raise_submit_form_failed', {
          label: 'hand_raise_lead_form',
        });
      });
    });

    describe('form cancel', () => {
      beforeEach(() => {
        findModal().vm.$emit('cancel');
      });

      it('tracks failed submission', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'hand_raise_form_canceled', {
          label: 'hand_raise_lead_form',
        });
      });
    });
  });
});

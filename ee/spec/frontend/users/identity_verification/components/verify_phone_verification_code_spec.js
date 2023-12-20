import { GlForm, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';

import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { sprintf } from '~/locale';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';

import { createAlert, VARIANT_SUCCESS } from '~/alert';

import VerifyPhoneVerificationCode from 'ee/users/identity_verification/components/verify_phone_verification_code.vue';
import {
  I18N_VERIFICATION_CODE_NAN_ERROR,
  I18N_VERIFICATION_CODE_BLANK_ERROR,
} from 'ee/users/identity_verification/constants';

jest.mock('~/alert');

describe('Verify phone verification code input component', () => {
  let wrapper;
  let axiosMock;

  const COUNTRY = 'US';
  const INTERNATIONAL_DIAL_CODE = '1';
  const NUMBER = '555';

  const SEND_CODE_PATH = '/users/identity_verification/send_phone_verification_code';
  const VERIFY_CODE_PATH = '/users/identity_verification/verify_phone_verification_code';

  const findForm = () => wrapper.findComponent(GlForm);

  const findVerificationCodeFormGroup = () => wrapper.findByTestId('verification-code-form-group');
  const findVerificationCodeInput = () => wrapper.findByTestId('verification-code-form-input');

  const findVerifyCodeButton = () => wrapper.findByText('Verify phone number');
  const findGoBackLink = () => wrapper.findByText('enter a new phone number');

  const enterCode = (value) => findVerificationCodeInput().vm.$emit('input', value);
  const submitForm = () => findForm().vm.$emit('submit', { preventDefault: jest.fn() });

  const findResendCodeButton = () => wrapper.findByText('Send a new code');
  const resendCode = () => findResendCodeButton().vm.$emit('click');

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(VerifyPhoneVerificationCode, {
      propsData: {
        latestPhoneNumber: {
          country: COUNTRY,
          internationalDialCode: INTERNATIONAL_DIAL_CODE,
          number: NUMBER,
        },
        ...props,
      },
      provide: {
        phoneNumber: {
          sendCodePath: SEND_CODE_PATH,
          verifyCodePath: VERIFY_CODE_PATH,
        },
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
    createAlert.mockClear();
  });

  describe('Verification Code input field', () => {
    it('should have label', () => {
      expect(findVerificationCodeFormGroup().attributes('label')).toBe('Verification code');
    });

    it('should have helper text with phone number', () => {
      expect(findVerificationCodeFormGroup().attributes('labeldescription')).toBe(
        sprintf("We've sent a verification code to +%{phoneNumber}", {
          phoneNumber: INTERNATIONAL_DIAL_CODE + NUMBER,
        }),
      );
    });

    it('should be of type number', () => {
      expect(findVerificationCodeInput().attributes('type')).toBe('number');
    });

    it.each`
      value       | valid    | errorMessage
      ${'123456'} | ${true}  | ${''}
      ${'abc'}    | ${false} | ${I18N_VERIFICATION_CODE_NAN_ERROR}
      ${''}       | ${false} | ${I18N_VERIFICATION_CODE_BLANK_ERROR}
    `(
      'when the input has a value of $value, then its validity should be $valid',
      async ({ value, valid, errorMessage }) => {
        enterCode(value);

        await nextTick();

        const expectedState = valid ? 'true' : undefined;
        const expectedButtonState = valid ? undefined : 'true';

        expect(findVerificationCodeFormGroup().attributes('invalid-feedback')).toBe(errorMessage);
        expect(findVerificationCodeFormGroup().attributes('state')).toBe(expectedState);

        expect(findVerificationCodeInput().attributes('state')).toBe(expectedState);

        expect(findVerifyCodeButton().attributes('disabled')).toBe(expectedButtonState);
      },
    );
  });

  describe('Go back to enter another phone number link', () => {
    beforeEach(() => {
      findGoBackLink().vm.$emit('click');
      return nextTick();
    });

    it('emits back event', () => {
      expect(wrapper.emitted('back')).toHaveLength(1);
    });

    it('resets form', () => {
      expect(findVerificationCodeFormGroup().attributes('invalid-feedback')).toBe('');
      expect(findVerificationCodeFormGroup().attributes('state')).toBe(undefined);

      expect(findVerificationCodeInput().attributes('value')).toBe('');
      expect(findVerificationCodeInput().attributes('state')).toBe(undefined);

      expect(findVerifyCodeButton().attributes('disabled')).toBeDefined();
    });
  });

  describe('Re-sending code', () => {
    describe('when request is successful', () => {
      beforeEach(() => {
        axiosMock.onPost(SEND_CODE_PATH).reply(HTTP_STATUS_OK, { success: true });

        createComponent({ additionalRequestParams: { captcha_token: '1234' } });

        resendCode();
        return waitForPromises();
      });

      it('emits `verification-attempt` event', () => {
        expect(wrapper.emitted('verification-attempt')).toHaveLength(1);
      });

      it('posts correct data with additional request params', () => {
        expect(axiosMock.history.post[0].data).toBe(
          JSON.stringify({
            country: 'US',
            international_dial_code: '1',
            phone_number: '555',
            captcha_token: '1234',
          }),
        );
      });

      it('renders success message', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: sprintf('We sent a new code to +%{phoneNumber}', {
            phoneNumber: INTERNATIONAL_DIAL_CODE + NUMBER,
          }),
          variant: VARIANT_SUCCESS,
        });
      });
    });

    describe('when request is unsuccessful', () => {
      beforeEach(() => {
        axiosMock
          .onPost(SEND_CODE_PATH)
          .reply(HTTP_STATUS_BAD_REQUEST, { message: 'Something went wrong' });

        resendCode();
        return waitForPromises();
      });

      it('emits `verification-attempt` event', () => {
        expect(wrapper.emitted('verification-attempt')).toHaveLength(1);
      });

      it('renders error message', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Something went wrong',
          captureError: true,
          error: expect.any(Error),
        });
      });
    });
  });

  describe('Verifying code', () => {
    describe('when request is successful', () => {
      beforeEach(() => {
        axiosMock.onPost(VERIFY_CODE_PATH).reply(HTTP_STATUS_OK, { success: true });

        createComponent({ additionalRequestParams: { captcha_token: '1234' } });

        enterCode('123');
        submitForm();
        return waitForPromises();
      });

      it('posts correct data with additional request params', () => {
        expect(axiosMock.history.post[0].data).toBe(
          JSON.stringify({
            verification_code: '123',
            captcha_token: '1234',
          }),
        );
      });

      it('does not emit `verification-attempt` event', () => {
        expect(wrapper.emitted('verification-attempt')).toBeUndefined();
      });

      it('emits next event with user entered phone number', () => {
        expect(wrapper.emitted('verified')).toHaveLength(1);
      });
    });

    describe('when request is unsuccessful', () => {
      const errorMessage = 'Enter a valid code';
      const reason = 'bad_request';

      beforeEach(() => {
        axiosMock
          .onPost(VERIFY_CODE_PATH)
          .reply(HTTP_STATUS_BAD_REQUEST, { message: errorMessage, reason });

        enterCode('000');
        submitForm();
        return waitForPromises();
      });

      it('emits `verification-attempt` event', () => {
        expect(wrapper.emitted('verification-attempt')).toHaveLength(1);
      });

      it('renders error message', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Enter a valid code',
          captureError: true,
          error: expect.any(Error),
        });
      });
    });

    describe('when TeleSign is down', () => {
      const errorMessage = 'Something went wrong';
      const reason = 'unknown_telesign_error';

      beforeEach(() => {
        axiosMock
          .onPost(VERIFY_CODE_PATH)
          .reply(HTTP_STATUS_BAD_REQUEST, { message: errorMessage, reason });

        enterCode('000');
        submitForm();
        return waitForPromises();
      });

      it('emits the verified event', () => {
        expect(wrapper.emitted('verified')).toHaveLength(1);
      });
    });

    describe('Captcha', () => {
      describe('when disableSubmitButton is true', () => {
        beforeEach(() => {
          createComponent({
            disableSubmitButton: true,
          });

          enterCode('000');
          return waitForPromises();
        });

        it('should disable the verify, go back and resend buttons', () => {
          expect(findVerifyCodeButton().attributes('disabled')).toBe('true');
          expect(findGoBackLink().exists()).toBe(false);
          expect(findResendCodeButton().exists()).toBe(false);
        });
      });
    });
  });
});

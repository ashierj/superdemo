import { within } from '@testing-library/dom';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ManageTwoFactorForm, {
  i18n,
} from '~/authentication/two_factor_auth/components/manage_two_factor_form.vue';

describe('ManageTwoFactorForm', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    wrapper = extendedWrapper(
      mount(ManageTwoFactorForm, {
        provide: {
          webauthnEnabled: options?.webauthnEnabled || false,
          profileTwoFactorAuthPath: '2fa_auth_path',
          profileTwoFactorAuthMethod: '2fa_auth_method',
          codesProfileTwoFactorAuthPath: '2fa_codes_path',
          codesProfileTwoFactorAuthMethod: '2fa_codes_method',
        },
      }),
    );
  };

  const queryByText = (text, options) => within(wrapper.element).queryByText(text, options);
  const queryByLabelText = (text, options) =>
    within(wrapper.element).queryByLabelText(text, options);

  beforeEach(() => {
    createComponent();
  });

  describe('Current password field', () => {
    it('renders the current password field', () => {
      expect(queryByLabelText(i18n.currentPassword).tagName).toEqual('INPUT');
    });
  });

  describe('Disable button', () => {
    it('renders the component correctly', () => {
      expect(wrapper).toMatchSnapshot();
      expect(wrapper.element).toMatchSnapshot();
    });

    it('has the right confirm text', () => {
      expect(wrapper.findByTestId('test-2fa-disable-button').element.dataset.confirm).toEqual(
        i18n.confirm,
      );
    });

    describe('when webauthnEnabled', () => {
      beforeEach(() => {
        createComponent({
          webauthnEnabled: true,
        });
      });

      it('has the right confirm text', () => {
        expect(wrapper.findByTestId('test-2fa-disable-button').element.dataset.confirm).toEqual(
          i18n.confirmWebAuthn,
        );
      });
    });

    it('modifies the form action and method when submitted through the button', async () => {
      const form = wrapper.find('form');
      const disableButton = wrapper.findByTestId('test-2fa-disable-button').element;
      const methodInput = wrapper.findByTestId('test-2fa-method-field').element;

      form.trigger('submit', { submitter: disableButton });

      await wrapper.vm.$nextTick();

      expect(form.element.getAttribute('action')).toEqual('2fa_auth_path');
      expect(methodInput.getAttribute('value')).toEqual('2fa_auth_method');
    });
  });

  describe('Regenerate recovery codes button', () => {
    it('renders the button', () => {
      expect(queryByText(i18n.regenerateRecoveryCodes)).toEqual(expect.any(HTMLElement));
    });

    it('modifies the form action and method when submitted through the button', async () => {
      const form = wrapper.find('form');
      const regenerateCodesButton = wrapper.findByTestId('test-2fa-regenerate-codes-button')
        .element;
      const methodInput = wrapper.findByTestId('test-2fa-method-field').element;

      form.trigger('submit', { submitter: regenerateCodesButton });

      await wrapper.vm.$nextTick();

      expect(form.element.getAttribute('action')).toEqual('2fa_codes_path');
      expect(methodInput.getAttribute('value')).toEqual('2fa_codes_method');
    });
  });
});

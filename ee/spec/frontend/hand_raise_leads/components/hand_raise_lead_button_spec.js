import { GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import HandRaiseLeadModal from 'ee/hand_raise_leads/hand_raise_lead/components/hand_raise_lead_modal.vue';
import HandRaiseLeadButton from 'ee/hand_raise_leads/hand_raise_lead/components/hand_raise_lead_button.vue';
import { PQL_BUTTON_TEXT } from 'ee/hand_raise_leads/hand_raise_lead/constants';
import { USER, CREATE_HAND_RAISE_LEAD_PATH } from './mock_data';

describe('HandRaiseLeadButton', () => {
  let wrapper;
  let trackingSpy;
  const ctaTracking = {};

  const createComponent = (providers = {}) => {
    return shallowMountExtended(HandRaiseLeadButton, {
      provide: {
        small: false,
        createHandRaiseLeadPath: CREATE_HAND_RAISE_LEAD_PATH,
        user: USER,
        ctaTracking,
        ...providers,
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(HandRaiseLeadModal);

  describe('rendering', () => {
    beforeEach(() => {
      wrapper = createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    it('does not have loading icon', () => {
      expect(findButton().props('loading')).toBe(false);
    });

    it('has default medium button and the "Contact sales" text on the button', () => {
      const button = findButton();

      expect(button.props('variant')).toBe('default');
      expect(button.props('size')).toBe('medium');
      expect(button.text()).toBe(PQL_BUTTON_TEXT);
    });

    it('renders the hand raise lead modal', () => {
      expect(findModal().exists()).toBe(true);
    });

    it('has the correct modal props', () => {
      expect(findModal().props('user')).toStrictEqual(USER);
      expect(findModal().props('submitPath')).toStrictEqual(CREATE_HAND_RAISE_LEAD_PATH);
      expect(findModal().props('ctaTracking')).toStrictEqual(ctaTracking);
    });

    describe('sets button attributes', () => {
      it('has all the set properties on the button', () => {
        const provide = {
          buttonAttributes: {
            href: '#',
            size: 'small',
            variant: 'confirm',
            buttonTextClasses: 'gl-font-sm',
          },
          buttonText: '_button_text_',
        };
        wrapper = createComponent(provide);
        const button = findButton();

        expect(button.props('variant')).toBe(provide.buttonAttributes.variant);
        expect(button.props('size')).toBe(provide.buttonAttributes.size);
        expect(button.props('buttonTextClasses')).toBe(provide.buttonAttributes.buttonTextClasses);
        expect(button.attributes('href')).toBe(provide.buttonAttributes.href);
        expect(button.text()).toBe(provide.buttonText);
      });
    });
  });

  describe('when provided with CTA tracking options', () => {
    const category = 'category';
    const action = 'click_button';
    const label = 'contact sales';
    const experiment = 'some_experiment';

    describe('when provided with all of the CTA tracking options', () => {
      const property = 'a thing';
      const value = '123';
      const localCtaTracking = { category, action, label, property, value, experiment };

      beforeEach(() => {
        wrapper = createComponent({
          ctaTracking: localCtaTracking,
        });
        trackingSpy = mockTracking(category, wrapper.element, jest.spyOn);
      });

      it('sets up tracking on the CTA button', () => {
        const button = findButton();

        button.vm.$emit('click');

        expect(trackingSpy).toHaveBeenCalledWith(category, action, {
          category,
          label,
          property,
          value,
          experiment,
        });
      });

      it('passes the ctaTracking to the modal', () => {
        expect(findModal().props('ctaTracking')).toStrictEqual(localCtaTracking);
      });
    });

    describe('when provided with only tracking label', () => {
      beforeEach(() => {
        wrapper = createComponent({
          ctaTracking: { label },
        });
        trackingSpy = mockTracking(category, wrapper.element, jest.spyOn);
      });

      it('does not track when action is missing', () => {
        const button = findButton();

        button.vm.$emit('click');

        expect(trackingSpy).not.toHaveBeenCalled();
      });
    });

    describe('when provided with none of the CTA tracking options', () => {
      beforeEach(() => {
        wrapper = createComponent();
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      });

      it('does not set up tracking on the CTA button', () => {
        const button = findButton();

        expect(button.attributes()).not.toMatchObject({ 'data-track-action': action });

        button.trigger('click');

        expect(trackingSpy).not.toHaveBeenCalled();
      });
    });
  });

  describe('loading', () => {
    it('changes the state of loading', async () => {
      wrapper = createComponent();

      findModal().vm.$emit('loading', true);
      await nextTick();

      expect(findButton().props('loading')).toBe(true);

      findModal().vm.$emit('loading', false);
      await nextTick();

      expect(findButton().props('loading')).toBe(false);
    });
  });
});

import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import HandRaiseLeadButton from 'ee/hand_raise_leads/hand_raise_lead/components/hand_raise_lead_button.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('HandRaiseLeadButton', () => {
  let wrapper;
  let trackingSpy;
  const ctaTracking = {};
  const buttonAttributes = {
    href: '#',
    buttonTextClasses: 'gl-font-sm',
  };

  const createComponent = (props = {}) => {
    return shallowMountExtended(HandRaiseLeadButton, {
      propsData: {
        modalId: '_some_id_',
        buttonText: '_button_text_',
        isLoading: false,
        buttonAttributes,
        ctaTracking,
        ...props,
      },
      directives: {
        glModal: createMockDirective('gl-modal'),
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);

  describe('rendering', () => {
    beforeEach(() => {
      wrapper = createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    it('does not have loading icon', () => {
      expect(findButton().props('loading')).toBe(false);
    });

    it('has default medium button', () => {
      const button = findButton();

      expect(button.props('variant')).toBe('default');
      expect(button.props('size')).toBe('medium');
      expect(button.text()).toBe('_button_text_');
    });

    it('button is bound to the modal', () => {
      const { value } = getBinding(findButton().element, 'gl-modal');

      expect(value).toBe('_some_id_');
    });

    describe('sets button attributes', () => {
      it('has all the set properties on the button', () => {
        const props = {
          buttonAttributes: {
            href: '#',
            size: 'small',
            variant: 'confirm',
            buttonTextClasses: 'gl-font-sm',
          },
          buttonText: '_other_button_text_',
        };
        wrapper = createComponent(props);
        const button = findButton();

        expect(button.props('variant')).toBe(props.buttonAttributes.variant);
        expect(button.props('size')).toBe(props.buttonAttributes.size);
        expect(button.props('buttonTextClasses')).toBe(props.buttonAttributes.buttonTextClasses);
        expect(button.attributes('href')).toBe(props.buttonAttributes.href);
        expect(button.text()).toBe(props.buttonText);
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
    it('changes the state of loading', () => {
      wrapper = createComponent();

      expect(findButton().props('loading')).toBe(false);

      wrapper = createComponent({ isLoading: true });

      expect(findButton().props('loading')).toBe(true);
    });
  });
});

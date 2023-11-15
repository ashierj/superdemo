import { nextTick } from 'vue';
import { GlButton, GlButtonGroup, GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import SplitButton from 'ee/vue_shared/security_reports/components/split_button.vue';
import * as urlUtility from '~/lib/utils/url_utility';

const defaultProps = {
  buttons: [
    {
      name: 'button one',
      tagline: "button one's tagline",
      isLoading: false,
      action: 'button1Action',
    },
    {
      name: 'button two',
      tagline: "button two's tagline",
      isLoading: false,
      action: 'button2Action',
    },
  ],
};

describe('Split Button', () => {
  let wrapper;

  const findButtonGroup = () => wrapper.findComponent(GlButtonGroup);
  const findButton = () => wrapper.findComponent(GlButton);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxItem = () => wrapper.findComponent(GlListboxItem);

  const createComponent = (props, mountFn = shallowMountExtended) => {
    wrapper = mountFn(SplitButton, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  it('does not render button group if buttons array is empty', () => {
    createComponent({ buttons: [] });

    expect(findButtonGroup().exists()).toBe(false);
  });

  it('renders disabled listbox and disabled button if disabled prop is true', () => {
    createComponent({ disabled: true });

    expect(findButton().attributes('disabled')).toBe('true');
    expect(findListbox().attributes('disabled')).toBe('true');
  });

  it('renders a loading icon in button and disables listbox when loading prop is true', () => {
    const { buttons } = defaultProps;

    createComponent({ buttons: [...buttons].map((b) => ({ ...b, loading: true })) });

    expect(findButton().props('loading')).toBe(true);
    expect(findListbox().props('disabled')).toBe(true);
  });

  it('renders a correct amount of listbox items', () => {
    createComponent();

    expect(findListbox().props('items')).toHaveLength(2);
  });

  it('renders both button text and tagline', () => {
    createComponent({}, mountExtended);

    const item = findListboxItem();
    expect(item.text()).toContain('button one');
    expect(item.text()).toContain("button one's tagline");
  });

  it('emits correct action on button click', () => {
    createComponent({}, mountExtended);

    findButton().vm.$emit('click');

    expect(wrapper.emitted('button1Action')).toBeDefined();
    expect(wrapper.emitted('button1Action')).toHaveLength(1);
  });

  it('visits url if href property is specified', () => {
    const spy = jest.spyOn(urlUtility, 'visitUrl').mockReturnValue({});
    const href = 'https://gitlab.com';
    const { buttons } = defaultProps;

    createComponent({ buttons: [{ ...buttons[0], href }] });

    findButton().vm.$emit('click');

    expect(wrapper.emitted('button1Action')).toBeUndefined();
    expect(spy).toHaveBeenCalledWith(href, true);
  });

  it('updates selected item', async () => {
    createComponent();

    findListbox().vm.$emit('select', 'button2Action');
    await nextTick();

    expect(findListbox().props('selected')).toBe('button2Action');
  });
});

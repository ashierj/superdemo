import { GlBadge, GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import PaidFeatureIndicator from 'ee/pages/projects/learn_gitlab/components/paid_feature_indicator.vue';

const trackLabel = 'add_code_owners';

describe('Paid Feature Indicator', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = shallowMount(PaidFeatureIndicator, {
      propsData: {
        trackLabel,
        planName: 'Ultimate',
      },
    });
  };

  const findGlBadge = () => wrapper.findComponent(GlBadge);
  const findGlTooltip = () => wrapper.findComponent(GlTooltip);

  beforeEach(() => {
    createWrapper();
  });

  it('renders badge', () => {
    expect(findGlBadge().exists()).toBe(true);
    expect(findGlBadge().text()).toBe('Ultimate');

    expect(findGlBadge().props()).toEqual({
      size: 'sm',
      variant: 'tier',
      icon: 'license-sm',
      iconSize: 'sm',
      roundIcon: false,
    });
  });

  it('renders tooltip', () => {
    expect(findGlTooltip().exists()).toBe(true);

    expect(findGlTooltip().attributes('title')).toBe(
      'After your 30-day trial, this feature is available on the Ultimate tier only.',
    );
  });

  it('tracks badge shown', () => {
    const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

    wrapper.findComponent(GlTooltip).vm.$emit('shown');

    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'render_tooltip', { label: trackLabel });

    unmockTracking();
  });
});

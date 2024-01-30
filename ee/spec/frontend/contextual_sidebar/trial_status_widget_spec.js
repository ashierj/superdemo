import { GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { WIDGET } from 'ee/contextual_sidebar/components/constants';
import TrialStatusWidget from 'ee/contextual_sidebar/components/trial_status_widget.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { stubExperiments } from 'helpers/experimentation_helper';
import { __ } from '~/locale';

describe('TrialStatusWidget component', () => {
  let wrapper;

  const { trackingEvents } = WIDGET;
  const trialDaysUsed = 10;
  const trialDuration = 30;

  const findGlLink = () => wrapper.findComponent(GlLink);
  const findLearnAboutFeaturesBtn = () => wrapper.findByTestId('learn-about-features-btn');
  const findLearnAboutFeaturesLink = () => wrapper.findByTestId('learn-about-features-link');

  const createComponent = (providers = {}) => {
    return mountExtended(TrialStatusWidget, {
      provide: {
        trialDaysUsed,
        trialDuration,
        navIconImagePath: 'illustrations/gitlab_logo.svg',
        percentageComplete: 10,
        planName: 'Ultimate',
        plansHref: 'billing/path-for/group',
        trialDiscoverPagePath: 'discover-path',
        ...providers,
      },
      stubs: { GlLink: true },
    });
  };

  describe('interpolated strings', () => {
    it('correctly interpolates them all', () => {
      wrapper = createComponent();

      expect(wrapper.text()).not.toMatch(/%{\w+}/);
    });
  });

  describe('without the optional containerId prop', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('matches the snapshot for namespace in active trial', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('matches the snapshot for namespace not in active trial', () => {
      wrapper = createComponent({ percentageComplete: 110 });

      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders without an id', () => {
      expect(findGlLink().attributes('id')).toBe(undefined);
    });

    describe('tracks when the widget menu is clicked', () => {
      let trackingSpy;

      beforeEach(() => {
        trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
      });

      afterEach(() => {
        unmockTracking();
      });

      it('tracks with correct information when namespace is in an active trial', async () => {
        const { category, label } = trackingEvents.activeTrialOptions;
        await wrapper.findByTestId('widget-menu').trigger('click');

        expect(trackingSpy).toHaveBeenCalledWith(category, trackingEvents.action, {
          category,
          label,
        });
      });

      it('tracks with correct information when namespace is not in an active trial', async () => {
        wrapper = createComponent({ percentageComplete: 110 });

        const { category, label } = trackingEvents.trialEndedOptions;
        await wrapper.findByTestId('widget-menu').trigger('click');

        expect(trackingSpy).toHaveBeenCalledWith(category, trackingEvents.action, {
          category,
          label,
        });
      });
    });

    it('does not render Trial twice if the plan name includes "Trial"', () => {
      wrapper = createComponent({ planName: 'Ultimate Trial' });

      expect(wrapper.text()).toMatchInterpolatedText('Ultimate Trial Day 10/30');
    });

    it('shows the expected day 1 text', () => {
      wrapper = createComponent({ trialDaysUsed: 1 });

      expect(wrapper.text()).toMatchInterpolatedText('Ultimate Trial Day 1/30');
    });

    it('shows the expected last day text', () => {
      wrapper = createComponent({ trialDaysUsed: 30 });

      expect(wrapper.text()).toMatchInterpolatedText('Ultimate Trial Day 30/30');
    });
  });

  describe('with the optional containerId prop', () => {
    beforeEach(() => {
      wrapper = createComponent({ containerId: 'some-id' });
    });

    it('renders with the given id', () => {
      expect(findGlLink().attributes('id')).toBe('some-id');
    });
  });

  describe('trial_discover_page experiment', () => {
    describe('when experiment is control', () => {
      beforeEach(() => {
        stubExperiments({ trial_discover_page: 'control' });
      });

      describe('when trial is active', () => {
        it('does not render link to discover page', () => {
          wrapper = createComponent();

          expect(wrapper.text()).not.toContain(__('Learn about features'));
          expect(findLearnAboutFeaturesBtn().exists()).toBe(false);
        });
      });

      describe('when trial is expired', () => {
        it('does not render link to discover page', () => {
          wrapper = createComponent({ percentageComplete: 110 });

          expect(wrapper.text()).not.toContain(__('Learn about features'));
          expect(findLearnAboutFeaturesLink().exists()).toBe(false);
        });
      });
    });

    describe('when experiment is candidate', () => {
      beforeEach(() => {
        stubExperiments({ trial_discover_page: 'candidate' });
      });

      describe('when trial is active', () => {
        it('renders link to discover page', () => {
          wrapper = createComponent();

          expect(wrapper.text()).toContain(__('Learn about features'));
          expect(findLearnAboutFeaturesBtn().exists()).toBe(true);
          expect(findLearnAboutFeaturesBtn().attributes('href')).toBe('discover-path');
        });
      });

      describe('when trial is expired', () => {
        it('renders link to discover page', () => {
          wrapper = createComponent({ percentageComplete: 110 });

          expect(wrapper.text()).toContain(__('Learn about features'));
          expect(findLearnAboutFeaturesLink().exists()).toBe(true);
          expect(findLearnAboutFeaturesLink().attributes('href')).toBe('discover-path');
        });
      });
    });
  });
});

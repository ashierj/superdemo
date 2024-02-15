import { GlLink, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { WIDGET } from 'ee/contextual_sidebar/components/constants';
import TrialStatusWidget from 'ee/contextual_sidebar/components/trial_status_widget.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { stubExperiments } from 'helpers/experimentation_helper';
import { __ } from '~/locale';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';

describe('TrialStatusWidget component', () => {
  let wrapper;
  let trackingSpy;

  const { trackingEvents } = WIDGET;
  const trialDaysUsed = 10;
  const trialDuration = 30;

  const findGlLink = () => wrapper.findComponent(GlLink);
  const findLearnAboutFeaturesBtn = () => wrapper.findByTestId('learn-about-features-btn');

  const createComponent = (providers = {}) => {
    return shallowMountExtended(TrialStatusWidget, {
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
      stubs: { GitlabExperiment, GlButton },
    });
  };

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
  });

  afterEach(() => {
    unmockTracking();
  });

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
          expect(findLearnAboutFeaturesBtn().exists()).toBe(false);
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

        it('tracks clicking learn about features button', async () => {
          wrapper = createComponent();

          const { category } = trackingEvents.activeTrialOptions;
          await findLearnAboutFeaturesBtn().trigger('click');

          expect(trackingSpy).toHaveBeenCalledWith(category, trackingEvents.action, {
            category,
            label: 'learn_about_features',
          });
        });
      });

      describe('when trial is expired', () => {
        it('renders link to discover page', () => {
          wrapper = createComponent({ percentageComplete: 110 });

          expect(wrapper.text()).toContain(__('Learn about features'));
          expect(findLearnAboutFeaturesBtn().exists()).toBe(true);
          expect(findLearnAboutFeaturesBtn().attributes('href')).toBe('discover-path');
        });

        it('tracks clicking learn about features link', async () => {
          wrapper = createComponent({ percentageComplete: 110 });

          const { category } = trackingEvents.trialEndedOptions;
          await findLearnAboutFeaturesBtn().trigger('click');

          expect(trackingSpy).toHaveBeenCalledWith(category, trackingEvents.action, {
            category,
            label: 'learn_about_features',
          });
        });
      });
    });
  });
});

import { GlPopover, GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { stubExperiments } from 'helpers/experimentation_helper';
import { TRACKING_CONTEXT_SCHEMA } from '~/experimentation/constants';
import eventHub from '~/invite_members/event_hub';
import LearnGitlabSectionLink from 'ee/pages/projects/learn_gitlab/components/learn_gitlab_section_link.vue';
import { ACTION_LABELS, PROMOTE_ULTIMATE_FEATURES } from 'ee/pages/projects/learn_gitlab/constants';
import { LEARN_GITLAB } from 'ee/invite_members/constants';
import { DOCS_URL_IN_EE_DIR } from 'jh_else_ce/lib/utils/url_utility';
import IncludedInTrialIndicator from 'ee/pages/projects/learn_gitlab/components/included_in_trial_indicator.vue';
import PaidFeatureIndicator from 'ee/pages/projects/learn_gitlab/components/paid_feature_indicator.vue';
import { testProviders } from './mock_data';

const defaultAction = 'gitWrite';
const defaultProps = {
  title: 'Create Repository',
  description: 'Some description',
  url: 'https://example.com',
  completed: false,
  enabled: true,
};

const openInNewTabProps = {
  url: `${DOCS_URL_IN_EE_DIR}/user/application_security/security_dashboard/`,
  openInNewTab: true,
};

describe('Learn GitLab Section Link', () => {
  let wrapper;

  const createWrapper = (action = defaultAction, props = {}, providers = testProviders) => {
    wrapper = extendedWrapper(
      mount(LearnGitlabSectionLink, {
        provide: { ...providers },
        propsData: { action, value: { ...defaultProps, ...props } },
      }),
    );
  };

  const findUncompletedLink = () => wrapper.find('[data-testid="uncompleted-learn-gitlab-link"]');
  const findDisabledLink = () => wrapper.findByTestId('disabled-learn-gitlab-link');
  const findPopoverTrigger = () => wrapper.findByTestId('contact-admin-popover-trigger');
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findPopoverLink = () => findPopover().findComponent(GlLink);
  const findIncludedInTrialIndicator = () => wrapper.findComponent(IncludedInTrialIndicator);
  const findPaidFeatureIndicator = () => wrapper.findComponent(PaidFeatureIndicator);

  it('renders no icon when not completed', () => {
    createWrapper(undefined, { completed: false });

    expect(wrapper.find('[data-testid="completed-icon"]').exists()).toBe(false);
  });

  it('renders the completion icon when completed', () => {
    createWrapper(undefined, { completed: true });

    expect(wrapper.find('[data-testid="completed-icon"]').exists()).toBe(true);
  });

  it('renders no trial only when it is not required', () => {
    createWrapper();

    expect(wrapper.find('[data-testid="trial-only"]').exists()).toBe(false);
  });

  it('renders trial only when trial is required', () => {
    createWrapper('codeOwnersEnabled');

    expect(wrapper.find('[data-testid="trial-only"]').exists()).toBe(true);
  });

  describe('disabled links', () => {
    beforeEach(() => {
      createWrapper('trialStarted', { enabled: false });
    });

    it('renders text without a link', () => {
      expect(findDisabledLink().exists()).toBe(true);
      expect(findDisabledLink().text()).toBe(ACTION_LABELS.trialStarted.title);
      expect(findDisabledLink().attributes('href')).toBeUndefined();
    });

    it('renders a popover trigger with question icon', () => {
      expect(findPopoverTrigger().exists()).toBe(true);
      expect(findPopoverTrigger().props('icon')).toBe('question-o');
      expect(findPopoverTrigger().attributes('aria-label')).toBe(
        LearnGitlabSectionLink.i18n.contactAdmin,
      );
    });

    it('renders a popover', () => {
      expect(findPopoverTrigger().attributes('id')).toBe(findPopover().props('target'));
      expect(findPopover().props()).toMatchObject({
        placement: 'top',
        triggers: 'hover focus',
      });
    });

    it('renders default disabled message', () => {
      expect(findPopover().text()).toContain(LearnGitlabSectionLink.i18n.contactAdmin);
    });

    it('renders custom disabled message if provided', () => {
      createWrapper('trialStarted', { enabled: false, message: 'Custom message' });
      expect(findPopover().text()).toContain('Custom message');
    });

    it('renders a link inside the popover', () => {
      expect(findPopoverLink().exists()).toBe(true);
      expect(findPopoverLink().attributes('href')).toBe(defaultProps.url);
    });
  });

  describe('links marked with openInNewTab', () => {
    beforeEach(() => {
      createWrapper('licenseScanningRun', openInNewTabProps);
    });

    it('renders links with blank target', () => {
      const linkElement = findUncompletedLink();

      expect(linkElement.exists()).toBe(true);
      expect(linkElement.attributes('target')).toEqual('_blank');
    });

    it('tracks the click', () => {
      const trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);

      findUncompletedLink().trigger('click');

      expect(trackingSpy).toHaveBeenCalledWith('_category_', 'click_link', {
        label: 'scan_dependencies_for_licenses',
      });

      unmockTracking();
    });
  });

  describe('clicking the link to open the invite_members modal', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation();

      createWrapper('userAdded', { url: '#' });
    });

    it('calls the eventHub', () => {
      findUncompletedLink().vm.$emit('click');

      expect(eventHub.$emit).toHaveBeenCalledWith('openModal', { source: LEARN_GITLAB });
    });

    it('tracks the click', () => {
      const trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);

      findUncompletedLink().trigger('click');

      expect(trackingSpy).toHaveBeenCalledWith('_category_', 'click_link', {
        label: 'invite_your_colleagues',
      });

      unmockTracking();
    });
  });

  describe('promote_ultimate_features experiment', () => {
    const trackExperimentOptions = (action, variant) => {
      const label = ACTION_LABELS[action].trackLabel;

      if (ACTION_LABELS[action].trialRequired) {
        return {
          label,
          context: {
            data: {
              variant,
              experiment: PROMOTE_ULTIMATE_FEATURES,
            },
            schema: TRACKING_CONTEXT_SCHEMA,
          },
        };
      }

      return { label };
    };

    it.each`
      action                 | variant
      ${'codeAdded'}         | ${'control'}
      ${'codeAdded'}         | ${'candidate'}
      ${'codeOwnersEnabled'} | ${'control'}
      ${'codeOwnersEnabled'} | ${'candidate'}
    `('tracks the click for $action action and $variant variant', ({ action, variant }) => {
      createWrapper(action);

      const trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);

      stubExperiments({ [PROMOTE_ULTIMATE_FEATURES]: variant });

      findUncompletedLink().trigger('click');

      expect(trackingSpy).toHaveBeenCalledWith(
        '_category_',
        'click_link',
        trackExperimentOptions(action, variant),
      );

      unmockTracking();
    });
  });

  describe('badge component', () => {
    describe('when does not promote ultimate features', () => {
      it('renders component', () => {
        createWrapper('codeOwnersEnabled', { completed: true });

        expect(findIncludedInTrialIndicator().exists()).toBe(true);
        expect(findPaidFeatureIndicator().exists()).toBe(false);
      });
    });

    describe('when promotes ultimate features', () => {
      it('renders component with tracking', () => {
        createWrapper('codeOwnersEnabled', { completed: true }, { promoteUltimateFeatures: true });

        const badgeComponent = findPaidFeatureIndicator();

        expect(findIncludedInTrialIndicator().exists()).toBe(false);
        expect(badgeComponent.exists()).toBe(true);
        expect(badgeComponent.props('planName')).toBe(ACTION_LABELS.codeOwnersEnabled.planName);
        expect(badgeComponent.props('trackLabel')).toBe(ACTION_LABELS.codeOwnersEnabled.trackLabel);
      });
    });
  });
});

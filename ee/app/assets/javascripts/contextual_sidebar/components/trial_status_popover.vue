<script>
import { GlButton, GlPopover, GlSprintf } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { debounce } from 'lodash';
import { removeTrialSuffix } from 'ee/billings/billings_util';
import { shouldHandRaiseLeadButtonMount } from 'ee/hand_raise_leads/hand_raise_lead';
import { formatDate } from '~/lib/utils/datetime_utility';
import { n__, sprintf } from '~/locale';
import Tracking from '~/tracking';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import { POPOVER, RESIZE_EVENT } from './constants';

const {
  i18n,
  trackingEvents,
  trialEndDateFormatString,
  resizeEventDebounceMS,
  disabledBreakpoints,
} = POPOVER;
const trackingMixin = Tracking.mixin({ experiment: 'trial_discover_page' });

export default {
  components: {
    GlButton,
    GlPopover,
    GlSprintf,
    GitlabExperiment,
  },
  mixins: [trackingMixin],
  inject: {
    containerId: {},
    daysRemaining: {},
    planName: {},
    plansHref: {},
    targetId: {},
    createHandRaiseLeadPath: {},
    trialEndDate: {},
    user: {},
    trialDiscoverPagePath: {},
  },
  data() {
    return {
      disabled: false,
    };
  },
  i18n,
  handRaiseLeadAttributes: {
    size: 'small',
    variant: 'confirm',
    category: 'secondary',
    class: 'gl-w-full',
    buttonTextClasses: 'gl-font-sm',
    href: '#',
  },
  computed: {
    isTrialActive() {
      return this.daysRemaining >= 0;
    },
    formattedTrialEndDate() {
      return formatDate(this.trialEndDate, trialEndDateFormatString, true);
    },
    planNameWithoutTrial() {
      return removeTrialSuffix(this.planName);
    },
    popoverTitle() {
      if (!this.isTrialActive) {
        return i18n.popoverTitleExpiredTrial;
      }

      const i18nPopoverTitle = n__(
        "Trials|You've got %{daysRemaining} day remaining on GitLab %{planName}!",
        "Trials|You've got %{daysRemaining} days remaining on GitLab %{planName}!",
        this.daysRemaining,
      );

      return sprintf(i18nPopoverTitle, {
        daysRemaining: this.daysRemaining,
        planName: this.planName,
      });
    },
    cssClasses() {
      const classList = ['gl-p-2'];

      if (!this.isTrialActive) {
        classList.push('gl-w-28');
      }

      return classList;
    },
    trialPopoverCategory() {
      return this.isTrialActive
        ? trackingEvents.activeTrialCategory
        : trackingEvents.trialEndedCategory;
    },
    handRaiseLeadBtnTracking() {
      const { action, label } = trackingEvents.contactSalesBtnClick;
      return {
        category: this.trialPopoverCategory,
        action,
        label,
      };
    },
  },
  created() {
    this.debouncedResize = debounce(() => this.updateDisabledState(), resizeEventDebounceMS);
    window.addEventListener(RESIZE_EVENT, this.debouncedResize);
  },
  mounted() {
    this.updateDisabledState();
  },
  beforeDestroy() {
    window.removeEventListener(RESIZE_EVENT, this.debouncedResize);
  },
  methods: {
    trackPageAction(eventName) {
      const { action, ...options } = trackingEvents[eventName];
      const category = this.trialPopoverCategory;

      this.track(action, { category, ...options });
    },
    updateDisabledState() {
      this.disabled = disabledBreakpoints.includes(bp.getBreakpointSize());
    },
    onShown() {
      this.trackPageAction('popoverShown');
      shouldHandRaiseLeadButtonMount();
    },
  },
};
</script>

<template>
  <gl-popover
    ref="popover"
    placement="rightbottom"
    boundary="viewport"
    :container="containerId"
    :target="targetId"
    :disabled="disabled"
    :delay="{ hide: 400 } /* eslint-disable-line @gitlab/vue-no-new-non-primitive-in-template */"
    :css-classes="cssClasses"
    @shown="onShown"
  >
    <template #title>
      <div :class="{ 'gl-font-size-h2': !isTrialActive }">
        {{ popoverTitle }}
      </div>
    </template>

    <gl-sprintf v-if="isTrialActive" :message="$options.i18n.popoverContent">
      <template #bold="{ content }">
        <b>{{ sprintf(content, { trialEndDate: formattedTrialEndDate }) }}</b>
      </template>
      <template #planName>{{ planNameWithoutTrial }}</template>
    </gl-sprintf>

    <div v-else>
      <p>{{ $options.i18n.popoverContentExpiredTrial }}</p>
    </div>

    <div class="gl-mt-5">
      <gl-button
        :href="plansHref"
        variant="confirm"
        size="small"
        class="gl-mb-3"
        block
        data-testid="compare-btn"
        :title="$options.i18n.compareAllButtonTitle"
        @click="trackPageAction('compareBtnClick')"
      >
        <span class="gl-font-sm">{{ $options.i18n.compareAllButtonTitle }}</span>
      </gl-button>

      <div
        class="js-hand-raise-lead-button"
        data-testid="contact-sales-btn"
        :data-create-hand-raise-lead-path="createHandRaiseLeadPath"
        :data-button-attributes="JSON.stringify($options.handRaiseLeadAttributes)"
        :data-namespace-id="user.namespaceId"
        :data-user-name="user.userName"
        :data-first-name="user.firstName"
        :data-last-name="user.lastName"
        :data-company-name="user.companyName"
        :data-glm-content="user.glmContent"
        :data-track-category="handRaiseLeadBtnTracking.category"
        :data-track-action="handRaiseLeadBtnTracking.action"
        :data-track-label="handRaiseLeadBtnTracking.label"
      ></div>

      <gitlab-experiment name="trial_discover_page">
        <template #candidate>
          <gl-button
            :href="trialDiscoverPagePath"
            variant="link"
            size="small"
            class="gl-mt-3"
            block
            data-testid="learn-about-features-btn"
            :title="$options.i18n.learnAboutButtonTitle"
            @click="trackPageAction('learnAboutFeaturesClick')"
          >
            <span class="gl-font-sm">{{ $options.i18n.learnAboutButtonTitle }}</span>
          </gl-button>
        </template>
      </gitlab-experiment>
    </div>
  </gl-popover>
</template>

<script>
import { GlBadge, GlTooltip } from '@gitlab/ui';
import Tracking from '~/tracking';
import { s__, sprintf } from '~/locale';
import { PROMOTE_ULTIMATE_FEATURES } from '../constants';

export default {
  components: {
    GlBadge,
    GlTooltip,
  },
  i18n: {
    tooltip: s__(
      'LearnGitlab|After your 30-day trial, this feature is available on the %{planName} tier only.',
    ),
  },
  mixins: [Tracking.mixin({ experiment: PROMOTE_ULTIMATE_FEATURES })],
  props: {
    planName: {
      type: String,
      required: true,
    },
    trackLabel: {
      type: String,
      required: true,
    },
  },
  computed: {
    title() {
      return sprintf(this.$options.i18n.tooltip, { planName: this.planName });
    },
  },
  methods: {
    onShown() {
      this.track('render_tooltip', { label: this.trackLabel });
    },
  },
};
</script>
<template>
  <span>
    <gl-tooltip
      placement="top"
      :target="() => $refs.paidFeatureIndicatorBadge"
      :title="title"
      @shown="onShown"
    />

    <span ref="paidFeatureIndicatorBadge">
      <gl-badge variant="tier" size="sm" icon="license-sm" icon-size="sm">
        {{ planName }}
      </gl-badge>
    </span>
  </span>
</template>

<script>
import GITLAB_LOGO_URL from '@gitlab/svgs/dist/illustrations/gitlab_logo.svg';

import {
  gray100,
  green400,
  brandOrange01,
  brandOrange02,
  brandOrange03,
} from '@gitlab/ui/scss_to_js/scss_variables';

export default {
  props: {
    percentage: {
      required: true,
      type: Number,
    },
  },
  computed: {
    progressBarColor() {
      if (this.percentage < 50) return brandOrange03;
      if (this.percentage < 75) return brandOrange02;
      if (this.percentage < 100) return brandOrange01;

      return green400; // == 100%
    },
    /* eslint-disable @gitlab/require-i18n-strings */
    // Progress bar styling variables
    progressBarStyle() {
      return {
        '--gray100': gray100,
        '--logo-url': `url(${GITLAB_LOGO_URL})`,
        '--percentage': `${this.percentage}%`,
        '--progress-bar-color': this.progressBarColor,
      };
    },
    /* eslint-enable @gitlab/require-i18n-strings */
  },
};
</script>

<template>
  <div class="circular-progress-bar" :style="progressBarStyle"></div>
</template>

<style scoped>
.circular-progress-bar {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 150px;
  height: 150px;
  border-radius: 50%;
  background: radial-gradient(closest-side, var(--white) 87%, transparent 88% 100%),
    conic-gradient(var(--progress-bar-color) var(--percentage), var(--gray100) 0);
}

.circular-progress-bar::before {
  content: var(--logo-url);
  transform: scale(2);
  margin-top: 10px;
}
</style>

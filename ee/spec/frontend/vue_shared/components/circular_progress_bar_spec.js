import { shallowMount } from '@vue/test-utils';

import {
  green400,
  brandOrange01,
  brandOrange02,
  brandOrange03,
} from '@gitlab/ui/scss_to_js/scss_variables';

import CircularProgressBar from 'ee/vue_shared/components/circular_progress_bar.vue';

describe('Learn GitLab', () => {
  let wrapper;

  const createWrapper = (propsData) => {
    wrapper = shallowMount(CircularProgressBar, { propsData });
  };

  describe('Circular Progress Bar', () => {
    it.each`
      percentage | color
      ${1}       | ${brandOrange03}
      ${49}      | ${brandOrange03}
      ${50}      | ${brandOrange02}
      ${51}      | ${brandOrange02}
      ${74}      | ${brandOrange02}
      ${75}      | ${brandOrange01}
      ${76}      | ${brandOrange01}
      ${99}      | ${brandOrange01}
      ${100}     | ${green400}
    `('renders $color color for $percentage%', ({ percentage, color }) => {
      createWrapper({ percentage });

      expect(wrapper.find('.circular-progress-bar').attributes('style')).toContain(
        `--percentage: ${percentage}%; --progress-bar-color: ${color};`,
      );
    });
  });
});

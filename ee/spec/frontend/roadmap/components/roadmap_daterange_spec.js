import { GlCollapsibleListbox, GlFormGroup, GlFormRadioGroup } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import * as actions from 'ee/roadmap/store/actions';
import state from 'ee/roadmap/store/state';
import mutations from 'ee/roadmap/store/mutations';
import RoadmapDaterange from 'ee/roadmap/components/roadmap_daterange.vue';
import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';

Vue.use(Vuex);

describe('RoadmapDaterange', () => {
  let wrapper;

  const quarters = { text: 'By quarter', value: PRESET_TYPES.QUARTERS };
  const months = { text: 'By month', value: PRESET_TYPES.MONTHS };
  const weeks = { text: 'By week', value: PRESET_TYPES.WEEKS };

  const createComponent = ({ timeframeRangeType = DATE_RANGES.CURRENT_QUARTER } = {}) => {
    const store = new Vuex.Store({
      actions: {
        ...actions,
        fetchGroupMilestones: jest.fn(),
        fetchMilestones: jest.fn(),
      },
      mutations,
      state: state(),
      getters: {
        isScopedRoadmap: (s) => Boolean(s.epicIid),
      },
    });

    store.dispatch('setInitialData', {
      presetType: PRESET_TYPES.MONTHS,
    });

    wrapper = shallowMountExtended(RoadmapDaterange, {
      store,
      propsData: { timeframeRangeType },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findFormRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);

  beforeEach(() => {
    createComponent();
  });

  describe('template', () => {
    it('renders labels', () => {
      expect(wrapper.find('label').exists()).toBe(true);
      expect(wrapper.find('label').text()).toContain('Date range');
    });

    it('renders dropdown', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it.each`
      timeframeRangeType             | hasFormGroup | availablePresets
      ${DATE_RANGES.CURRENT_QUARTER} | ${false}     | ${[]}
      ${DATE_RANGES.CURRENT_YEAR}    | ${true}      | ${[months, weeks]}
      ${DATE_RANGES.THREE_YEARS}     | ${true}      | ${[quarters, months, weeks]}
    `(
      'renders radio group depending on timeframeRangeType',
      async ({ timeframeRangeType, hasFormGroup, availablePresets }) => {
        createComponent({ timeframeRangeType });

        await nextTick();

        expect(findFormGroup().exists()).toBe(hasFormGroup);
        if (hasFormGroup) {
          expect(findFormRadioGroup().props('options')).toEqual(availablePresets);
        }
      },
    );
  });

  describe('dropdown behavior', () => {
    beforeEach(() => {
      createComponent();
    });

    it('changes the date range when the dropdown closes', async () => {
      expect(findDropdown().props('selected')).toBe(DATE_RANGES.CURRENT_QUARTER);

      findDropdown().vm.$emit('select', DATE_RANGES.CURRENT_YEAR);

      await nextTick();

      findDropdown().vm.$emit('hidden');

      await nextTick();

      expect(findDropdown().props('selected')).toBe(DATE_RANGES.CURRENT_YEAR);
    });
  });
});

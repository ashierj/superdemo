import { GlCollapsibleListbox } from '@gitlab/ui';
import BaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/scan_result_policy/base_layout/base_layout_component.vue';
import AgeFilter from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/age_filter.vue';
import NumberRangeSelect from 'ee/security_orchestration/components/policy_editor/scan_result_policy/number_range_select.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  ANY_OPERATOR,
  GREATER_THAN_OPERATOR,
  LESS_THAN_OPERATOR,
} from 'ee/security_orchestration/components/policy_editor/constants';
import {
  AGE,
  AGE_INTERVALS,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/constants';

describe('AgeFilter', () => {
  let wrapper;

  const [{ value: intervalDay }, { value: intervalWeek }] = AGE_INTERVALS;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(AgeFilter, {
      propsData: {
        ...props,
      },
      stubs: {
        BaseLayoutComponent,
        GlCollapsibleListbox,
      },
    });
  };

  const findBaseLayoutComponent = () => wrapper.findComponent(BaseLayoutComponent);
  const findNumberRangeSelect = () => wrapper.findComponent(NumberRangeSelect);
  const findIntervalSelect = () => wrapper.findComponent(GlCollapsibleListbox);

  it('renders operator dropdown', () => {
    createComponent();

    expect(findNumberRangeSelect().exists()).toBe(true);
  });

  it('renders initially as ANY_OPERATOR', () => {
    createComponent();

    expect(findNumberRangeSelect().props('selected')).toEqual(ANY_OPERATOR);
  });

  it.each([GREATER_THAN_OPERATOR, LESS_THAN_OPERATOR])(
    'renders the interval listbox for %s operator',
    (operator) => {
      createComponent({ selected: { operator } });

      expect(findIntervalSelect().exists()).toEqual(true);
    },
  );

  it('emits change when setting an operator', async () => {
    createComponent();

    await findNumberRangeSelect().vm.$emit('operator-change', GREATER_THAN_OPERATOR);

    expect(wrapper.emitted('input')).toEqual([
      [{ interval: intervalDay, operator: GREATER_THAN_OPERATOR, value: 0 }],
    ]);
  });

  it('emits change when setting a value', async () => {
    createComponent({
      selected: { operator: GREATER_THAN_OPERATOR, interval: intervalDay, value: 1 },
    });

    await findNumberRangeSelect().vm.$emit('input', 2);

    expect(wrapper.emitted('input')).toEqual([
      [{ interval: intervalDay, operator: GREATER_THAN_OPERATOR, value: 2 }],
    ]);
  });

  it('emits change when setting an interval', async () => {
    createComponent({ selected: { operator: GREATER_THAN_OPERATOR } });

    await findIntervalSelect().vm.$emit('select', intervalWeek);

    expect(wrapper.emitted('input')).toEqual([
      [{ interval: intervalWeek, operator: GREATER_THAN_OPERATOR, value: 0 }],
    ]);
  });

  describe('remove', () => {
    it('should emit remove event', async () => {
      createComponent({
        selected: { operator: GREATER_THAN_OPERATOR, value: 1, interval: intervalDay },
      });

      await findBaseLayoutComponent().vm.$emit('remove');

      expect(wrapper.emitted('remove')).toEqual([[AGE]]);
    });
  });
});

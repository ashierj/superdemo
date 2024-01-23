import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupByFilter from 'ee/metrics/details/filter_bar/groupby_filter.vue';

describe('GroupByFilter', () => {
  let wrapper;

  const props = {
    searchConfig: {
      groupByFunctions: ['sum', 'avg'],
      dimensions: ['dimension_one', 'dimensions_two'],
    },
    selectedDimensions: ['dimension_one'],
    selectedFunction: 'sum',
  };

  const mount = () => {
    wrapper = shallowMountExtended(GroupByFilter, {
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    mount();
  });

  it('renders the group by function dropdown', () => {
    expect(wrapper.findByTestId('group-by-function-dropdown').props('items')).toEqual([
      { value: 'sum', text: 'sum' },
      { value: 'avg', text: 'avg' },
    ]);
    expect(wrapper.findByTestId('group-by-function-dropdown').props('selected')).toEqual(
      props.selectedFunction,
    );
  });

  it('renders the group by dimensions dropdown', () => {
    expect(wrapper.findByTestId('group-by-dimensions-dropdown').props('items')).toEqual([
      { value: 'dimension_one', text: 'dimension_one' },
      { value: 'dimensions_two', text: 'dimensions_two' },
    ]);
    expect(wrapper.findByTestId('group-by-dimensions-dropdown').props('selected')).toEqual(
      props.selectedDimensions,
    );
  });

  it('emits groupBy on function change', async () => {
    await wrapper.findByTestId('group-by-function-dropdown').vm.$emit('select', 'avg');

    expect(wrapper.emitted('groupBy')).toEqual([
      [
        {
          dimensions: props.selectedDimensions,
          func: 'avg',
        },
      ],
    ]);
  });

  it('emits groupBy on dimension change', async () => {
    await wrapper
      .findByTestId('group-by-dimensions-dropdown')
      .vm.$emit('select', ['dimension_two']);

    expect(wrapper.emitted('groupBy')).toEqual([
      [
        {
          dimensions: ['dimension_two'],
          func: props.selectedFunction,
        },
      ],
    ]);
  });

  it('updates the group-by toggle text depending on value', async () => {
    expect(wrapper.findByTestId('group-by-dimensions-dropdown').props('toggleText')).toBe(
      'dimension_one',
    );

    await wrapper
      .findByTestId('group-by-dimensions-dropdown')
      .vm.$emit('select', ['dimension_two']);

    expect(wrapper.findByTestId('group-by-dimensions-dropdown').props('toggleText')).toBe(
      'dimension_two',
    );

    await wrapper
      .findByTestId('group-by-dimensions-dropdown')
      .vm.$emit('select', ['dimension_two', 'dimensions_one']);

    expect(wrapper.findByTestId('group-by-dimensions-dropdown').props('toggleText')).toBe(
      'multiple',
    );
  });

  it('updates the group-by label depending on value', async () => {
    expect(wrapper.findByTestId('group-by-label').text()).toBe('');

    await wrapper
      .findByTestId('group-by-dimensions-dropdown')
      .vm.$emit('select', ['dimension_two']);

    expect(wrapper.findByTestId('group-by-label').text()).toBe('');

    await wrapper
      .findByTestId('group-by-dimensions-dropdown')
      .vm.$emit('select', ['dimension_two', 'dimensions_one']);

    expect(wrapper.findByTestId('group-by-label').text()).toBe('dimension_two, dimensions_one');
  });
});

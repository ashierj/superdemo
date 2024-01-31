import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupByFilter from 'ee/metrics/details/filter_bar/groupby_filter.vue';

describe('GroupByFilter', () => {
  let wrapper;

  const props = {
    searchMetadata: {
      name: 'cpu_seconds_total',
      type: 'sum',
      description: 'some_description',
      last_ingested_at: 1705374438711900000,
      attribute_keys: ['attribute_one', 'attributes_two'],
      supported_aggregations: ['1m', '1h'],
      supported_functions: ['sum', 'avg'],
      default_group_by_attributes: ['attribute_one', 'attributes_two'],
      default_group_by_function: 'avg',
    },
    selectedAttributes: ['attribute_one'],
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

  it('renders the group by attributes dropdown', () => {
    expect(wrapper.findByTestId('group-by-attributes-dropdown').props('items')).toEqual([
      { value: 'attribute_one', text: 'attribute_one' },
      { value: 'attributes_two', text: 'attributes_two' },
    ]);
    expect(wrapper.findByTestId('group-by-attributes-dropdown').props('selected')).toEqual(
      props.selectedAttributes,
    );
  });

  it('emits groupBy on function change', async () => {
    await wrapper.findByTestId('group-by-function-dropdown').vm.$emit('select', 'avg');

    expect(wrapper.emitted('groupBy')).toEqual([
      [
        {
          attributes: props.selectedAttributes,
          func: 'avg',
        },
      ],
    ]);
  });

  it('emits groupBy on attribute change', async () => {
    await wrapper
      .findByTestId('group-by-attributes-dropdown')
      .vm.$emit('select', ['attribute_two']);

    expect(wrapper.emitted('groupBy')).toEqual([
      [
        {
          attributes: ['attribute_two'],
          func: props.selectedFunction,
        },
      ],
    ]);
  });

  it('updates the group-by toggle text depending on value', async () => {
    expect(wrapper.findByTestId('group-by-attributes-dropdown').props('toggleText')).toBe(
      'attribute_one',
    );

    await wrapper
      .findByTestId('group-by-attributes-dropdown')
      .vm.$emit('select', ['attribute_two']);

    expect(wrapper.findByTestId('group-by-attributes-dropdown').props('toggleText')).toBe(
      'attribute_two',
    );

    await wrapper
      .findByTestId('group-by-attributes-dropdown')
      .vm.$emit('select', ['attribute_two', 'attributes_one']);

    expect(wrapper.findByTestId('group-by-attributes-dropdown').props('toggleText')).toBe(
      'multiple',
    );
  });

  it('updates the group-by label depending on value', async () => {
    expect(wrapper.findByTestId('group-by-label').text()).toBe('');

    await wrapper
      .findByTestId('group-by-attributes-dropdown')
      .vm.$emit('select', ['attribute_two']);

    expect(wrapper.findByTestId('group-by-label').text()).toBe('');

    await wrapper
      .findByTestId('group-by-attributes-dropdown')
      .vm.$emit('select', ['attribute_two', 'attributes_one']);

    expect(wrapper.findByTestId('group-by-label').text()).toBe('attribute_two, attributes_one');
  });
});

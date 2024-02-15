import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupByFilter from 'ee/metrics/details/filter_bar/groupby_filter.vue';

describe('GroupByFilter', () => {
  let wrapper;

  const props = {
    supportedAttributes: ['attribute_one', 'attributes_two', 'attributes_three'],
    supportedFunctions: ['sum', 'avg'],
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

  const findGroupByFunctionDropdown = () => wrapper.findByTestId('group-by-function-dropdown');
  const findGroupByAttributesDropdown = () => wrapper.findByTestId('group-by-attributes-dropdown');
  const findGroupByLabel = () => wrapper.findByTestId('group-by-label');

  it('renders the group by function dropdown', () => {
    expect(findGroupByFunctionDropdown().props('items')).toEqual([
      { value: 'sum', text: 'sum' },
      { value: 'avg', text: 'avg' },
    ]);
    expect(findGroupByFunctionDropdown().props('selected')).toEqual(props.selectedFunction);
  });

  it('renders the group by attributes dropdown', () => {
    expect(findGroupByAttributesDropdown().props('items')).toEqual([
      { value: 'attribute_one', text: 'attribute_one' },
      { value: 'attributes_two', text: 'attributes_two' },
      { value: 'attributes_three', text: 'attributes_three' },
    ]);
    expect(findGroupByAttributesDropdown().props('selected')).toEqual(props.selectedAttributes);
  });

  it('emits groupBy on function change', async () => {
    await findGroupByFunctionDropdown().vm.$emit('select', 'avg');

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
    await findGroupByAttributesDropdown().vm.$emit('select', ['attribute_two']);

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
    expect(findGroupByAttributesDropdown().props('toggleText')).toBe('attribute_one');

    await findGroupByAttributesDropdown().vm.$emit('select', ['attribute_two']);

    expect(findGroupByAttributesDropdown().props('toggleText')).toBe('attribute_two');

    await findGroupByAttributesDropdown().vm.$emit('select', ['attribute_two', 'attributes_one']);

    expect(findGroupByAttributesDropdown().props('toggleText')).toBe('multiple');

    await findGroupByAttributesDropdown().vm.$emit('select', [
      'attribute_two',
      'attributes_one',
      'attributes_threww',
    ]);

    expect(findGroupByAttributesDropdown().props('toggleText')).toBe('all');

    await findGroupByAttributesDropdown().vm.$emit('select', []);

    expect(findGroupByAttributesDropdown().props('toggleText')).toBe('Select attributes');
  });

  it('updates the group-by label depending on value', async () => {
    expect(findGroupByLabel().text()).toBe('');

    await findGroupByAttributesDropdown().vm.$emit('select', ['attribute_two']);

    expect(findGroupByLabel().text()).toBe('');

    await findGroupByAttributesDropdown().vm.$emit('select', ['attribute_two', 'attributes_one']);

    expect(findGroupByLabel().text()).toBe('attribute_two, attributes_one');
  });
});

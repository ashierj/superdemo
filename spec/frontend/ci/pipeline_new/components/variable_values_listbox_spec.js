import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import VariableValuesListbox from '~/ci/pipeline_new/components/variable_values_listbox.vue';
import { mockYamlVariables } from '../mock_data';

const { value, valueOptions } = mockYamlVariables[2];

describe('Variable values listbox', () => {
  let wrapper;

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxItems = () => wrapper.findAllByTestId('ci-variable-value-dropdown-item');
  const search = (searchString) => findListbox().vm.$emit('search', searchString);

  const createComponent = () => {
    wrapper = shallowMountExtended(VariableValuesListbox, {
      propsData: {
        selected: value,
        items: valueOptions.map((option) => ({
          text: option,
          value: option,
        })),
      },
      stubs: {
        GlCollapsibleListbox,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('multiple predefined values are rendered as a dropdown', () => {
    for (let i = 0; i < valueOptions.length; i += 1) {
      expect(findListboxItems().at(i).text()).toBe(valueOptions[i]);
    }
  });

  it('variable with multiple predefined values sets value as the default', () => {
    expect(findListbox().props('selected')).toBe(value);
  });

  it('filters options based on search', async () => {
    const searchString = 'prod';

    search(searchString);

    await waitForPromises();

    expect(findListboxItems().length).toBe(1);
    expect(findListboxItems().at(0).text()).toContain(searchString);

    search('');

    await waitForPromises();

    expect(findListboxItems().length).toBe(3);
  });

  it('filters options with fuzzy filtering', async () => {
    const searchString = 'poduct';

    search(searchString);

    await waitForPromises();

    expect(findListboxItems().length).toBe(1);
    expect(findListboxItems().at(0).text()).toBe('production');
  });
});

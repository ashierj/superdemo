import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import RunnerUsageTable from 'ee/ci/runner/components/runner_usage_table.vue';

describe('RunnerUsageTable', () => {
  let wrapper;

  const createWrapper = (options) => {
    wrapper = shallowMountExtended(RunnerUsageTable, {
      ...options,
    });
  };

  it('renders table', () => {
    createWrapper();

    expect(wrapper.find('table').exists()).toBe(true);
  });

  it('renders table headers', () => {
    createWrapper({
      slots: {
        name: 'Top results',
      },
    });

    const [th1, th2] = wrapper.findAll('th').wrappers;
    expect(th1.text()).toBe('Top results');
    expect(th2.text()).toBe('Usage (min)');
  });

  it('renders table content', () => {
    createWrapper({
      slots: {
        default: `<tr>
          <td>Result</td>
          <td>10</td>
        </tr>`,
      },
    });

    expect(wrapper.find('tbody tr').text()).toBe('Result 10');
  });
});

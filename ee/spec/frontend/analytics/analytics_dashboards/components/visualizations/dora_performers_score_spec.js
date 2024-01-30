import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DoraPerformersScore from 'ee/analytics/analytics_dashboards/components/visualizations/dora_performers_score.vue';
import DoraChart from 'ee/analytics/dashboards/components/dora_performers_score_chart.vue';

describe('DoraPerformersScore Visualization', () => {
  let wrapper;

  const namespace = {
    title: 'Awesome Co. project',
    requestPath: 'some/fake/path',
    isProject: false,
  };

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(DoraPerformersScore, {
      propsData: {
        data: { namespace },
        options: {},
        ...props,
      },
    });
  };

  const findChart = () => wrapper.findComponent(DoraChart);

  describe('for groups', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the panel', () => {
      expect(findChart().props().data).toMatchObject({
        namespace: namespace.requestPath,
      });
    });
  });

  describe('for projects', () => {
    const projectNamespace = { ...namespace, isProject: true };
    beforeEach(() => {
      createWrapper({ data: { namespace: projectNamespace } });
    });

    it('does not render the panel', () => {
      expect(findChart().exists()).toBe(false);
    });

    it('emits an error event', () => {
      const emitted = wrapper.emitted('error');
      expect(emitted).toHaveLength(1);
      expect(emitted[0]).toEqual([
        { error: 'This visualization is not supported for project namespaces.', canRetry: false },
      ]);
    });
  });
});

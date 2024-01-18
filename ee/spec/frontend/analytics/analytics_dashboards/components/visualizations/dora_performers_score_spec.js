import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DoraPerformersScore from 'ee/analytics/analytics_dashboards/components/visualizations/dora_performers_score.vue';
import DoraChart from 'ee/analytics/dashboards/components/dora_performers_score.vue';

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
  const findError = () => wrapper.findComponent(GlAlert);

  describe('for groups', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the panel', () => {
      expect(findError().exists()).toBe(false);
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

    it('shows an error alert', () => {
      expect(findChart().exists()).toBe(false);
      expect(findError().text()).toBe(
        'This visualization is not supported for project namespaces.',
      );
    });
  });
});

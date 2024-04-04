import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AiImpactTable from 'ee/analytics/analytics_dashboards/components/visualizations/ai_impact_table.vue';

describe('AI Impact Table Visualization', () => {
  let wrapper;

  const namespace = 'Klaptrap';
  const title = `Metric trends for group: ${namespace}`;

  const createWrapper = () => {
    wrapper = shallowMountExtended(AiImpactTable, {
      propsData: {
        data: { namespace, title },
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the placeholder content', () => {
      expect(wrapper.text()).toContain(title);
    });
  });
});

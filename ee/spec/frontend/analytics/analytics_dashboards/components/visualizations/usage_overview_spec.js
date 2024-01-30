import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import UsageOverview from 'ee/analytics/analytics_dashboards/components/visualizations/usage_overview.vue';
import { mockUsageMetrics, mockUsageMetricsNoData } from '../../mock_data';

describe('Single Stat Visualization', () => {
  let wrapper;
  const defaultProps = { data: mockUsageMetrics, options: {} };

  const findMetrics = () => wrapper.findAllComponents(GlSingleStat);

  const findMetricProperty = (property, idx) => wrapper.findAllByTestId(property).at(idx);
  const findMetricTitle = (idx) => findMetricProperty('title-text', idx);
  const findMetricIcon = (idx) => findMetricProperty('title-icon', idx);
  const findMetricValue = (idx) => findMetricProperty('displayValue', idx);

  const createWrapper = (props = defaultProps) => {
    wrapper = mountExtended(UsageOverview, {
      propsData: {
        data: props.data,
        options: props.options,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render each metric', () => {
      expect(findMetrics()).toHaveLength(mockUsageMetrics.length);
    });

    it('should render each metric as a single stat', () => {
      mockUsageMetrics.forEach(({ value, options }, idx) => {
        expect(findMetricTitle(idx).text()).toBe(options.title);
        expect(findMetricIcon(idx).props('name')).toBe(options.titleIcon);
        expect(findMetricValue(idx).text()).toBe(String(value));
      });
    });

    it('emits `showTooltip` with the latest metric.recordedAt as the last updated time', () => {
      expect(wrapper.emitted('showTooltip')).toHaveLength(1);
      expect(wrapper.emitted('showTooltip')[0][0]).toEqual(
        'Statistics on top-level namespace usage. Usage data is a cumulative count, and updated monthly. Last updated: 2023-11-27 11:59 PM',
      );
    });
  });

  describe('with no data', () => {
    beforeEach(() => {
      createWrapper({ data: mockUsageMetricsNoData });
    });

    it('should render each metric', () => {
      expect(findMetrics()).toHaveLength(mockUsageMetrics.length);
    });

    it('should render each metric as a single stat with value 0', () => {
      mockUsageMetrics.forEach((_, idx) => {
        expect(findMetricValue(idx).text()).toBe('0');
      });
    });

    it('emits `showTooltip` without the last updated time', () => {
      expect(wrapper.emitted('showTooltip')).toHaveLength(1);
      expect(wrapper.emitted('showTooltip')[0][0]).toEqual(
        'Statistics on top-level namespace usage. Usage data is a cumulative count, and updated monthly.',
      );
    });
  });
});

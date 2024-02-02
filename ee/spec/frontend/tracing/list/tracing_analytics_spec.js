import { GlLineChart, GlColumnChart } from '@gitlab/ui/dist/charts';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TracingAnalytics from 'ee/tracing/list/tracing_analytics.vue';
import * as commonUtils from '~/lib/utils/common_utils';

describe('TracingAnalytics', () => {
  let wrapper;

  const mockAnalytics = [
    {
      interval: 1706456580,
      count: 272,
      p90_duration_nano: 79431434,
      p95_duration_nano: 172512624,
      p75_duration_nano: 33666014,
      p50_duration_nano: 13540992,
      trace_rate: 4.533333333333333,
      error_rate: 1.2,
    },
    {
      interval: 1706456640,
      count: 322,
      p90_duration_nano: 245701137,
      p95_duration_nano: 410402110,
      p75_duration_nano: 126097516,
      p50_duration_nano: 26955796,
      trace_rate: 5.366666666666666,
      error_rate: undefined,
    },
    {
      interval: 1706456700,
      count: 317,
      p90_duration_nano: 57725645,
      p95_duration_nano: 108238301,
      p75_duration_nano: 22083152,
      p50_duration_nano: 9805219,
      trace_rate: 5.283333333333333,
      error_rate: 0.234235,
    },
  ];

  const mountComponent = (analytics = mockAnalytics) => {
    wrapper = shallowMountExtended(TracingAnalytics, {
      propsData: {
        analytics,
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  const findChart = () => wrapper.findComponent(TracingAnalytics);

  describe('volume chart', () => {
    it('renders a column chart with volume data', () => {
      const chart = findChart().findComponent(GlColumnChart);
      expect(chart.props('bars')[0].data).toEqual([
        [new Date('2024-01-28T15:43:00.000Z'), '4.53'],
        [new Date('2024-01-28T15:44:00.000Z'), '5.37'],
        [new Date('2024-01-28T15:45:00.000Z'), '5.28'],
      ]);
    });
  });

  describe('error chart', () => {
    it('renders a line chart with error data', () => {
      const chart = findChart().findComponent(GlLineChart);
      expect(chart.props('data')[0].data).toEqual([
        [new Date('2024-01-28T15:43:00.000Z'), '100.00'],
        [new Date('2024-01-28T15:44:00.000Z'), '0.00'],
        [new Date('2024-01-28T15:45:00.000Z'), '23.42'],
      ]);
    });
  });

  describe('duration chart', () => {
    it('renders a line chart with error data', () => {
      const chart = findChart().findAllComponents(GlLineChart).at(1);
      expect(chart.props('data')[0].data).toEqual([
        [new Date('2024-01-28T15:43:00.000Z'), '79.43'],
        [new Date('2024-01-28T15:44:00.000Z'), '245.70'],
        [new Date('2024-01-28T15:45:00.000Z'), '57.73'],
      ]);
    });
  });

  describe('height', () => {
    it('sets the chart height to 20% of the container height', () => {
      jest.spyOn(commonUtils, 'contentTop').mockReturnValue(200);
      window.innerHeight = 1000;

      mountComponent();

      const chart = findChart().findComponent(GlColumnChart);
      expect(chart.props('height')).toBe(160);
    });

    it('sets the min height to 100px', () => {
      jest.spyOn(commonUtils, 'contentTop').mockReturnValue(20);
      window.innerHeight = 200;

      mountComponent();

      const chart = findChart().findComponent(GlColumnChart);
      expect(chart.props('height')).toBe(100);
    });

    it('resize the chart on window resize', async () => {
      jest.spyOn(commonUtils, 'contentTop').mockReturnValue(200);
      window.innerHeight = 1000;

      mountComponent();

      expect(wrapper.findComponent(GlColumnChart).props('height')).toBe(160);

      jest.spyOn(commonUtils, 'contentTop').mockReturnValue(200);
      window.innerHeight = 800;
      window.dispatchEvent(new Event('resize'));

      await nextTick();

      expect(wrapper.findComponent(GlColumnChart).props('height')).toBe(120);
    });
  });
});

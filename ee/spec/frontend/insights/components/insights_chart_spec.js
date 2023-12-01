import { nextTick } from 'vue';
import { GlColumnChart, GlLineChart, GlStackedColumnChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import { visitUrl } from '~/lib/utils/url_utility';

import InsightsChart from 'ee/insights/components/insights_chart.vue';
import InsightsChartError from 'ee/insights/components/insights_chart_error.vue';
import {
  CHART_TYPES,
  INSIGHTS_CHARTS_SUPPORT_DRILLDOWN,
  INSIGHTS_DRILLTHROUGH_PATH_SUFFIXES,
  ISSUABLE_TYPES,
} from 'ee/insights/constants';
import {
  chartInfo,
  barChartData,
  lineChartData,
  stackedBarChartData,
  chartDataSeriesParams,
  chartUndefinedDataSeriesParams,
} from 'ee_jest/insights/mock_data';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

describe('Insights chart component', () => {
  let wrapper;

  const groupPath = 'test';
  const projectPath = 'test/project';

  const DEFAULT_PROVIDE = {
    fullPath: groupPath,
    isProject: false,
  };

  const createWrapper = ({ props = {}, provide = DEFAULT_PROVIDE } = {}) => {
    wrapper = shallowMount(InsightsChart, {
      propsData: {
        loaded: true,
        type: chartInfo.type,
        title: chartInfo.title,
        data: null,
        error: '',
        ...props,
      },
      provide,
      stubs: { 'gl-column-chart': true, 'insights-chart-error': true },
    });
  };

  const findChart = (component) => wrapper.findComponent(component);

  describe('when chart is loading', () => {
    it('displays the chart loader in the container', () => {
      createWrapper({ props: { loaded: false } });

      expect(wrapper.findComponent(ChartSkeletonLoader).exists()).toBe(true);
    });
  });

  describe.each`
    type                       | component               | name                      | data
    ${CHART_TYPES.BAR}         | ${GlColumnChart}        | ${'GlColumnChart'}        | ${barChartData}
    ${CHART_TYPES.LINE}        | ${GlLineChart}          | ${'GlLineChart'}          | ${lineChartData}
    ${CHART_TYPES.STACKED_BAR} | ${GlStackedColumnChart} | ${'GlStackedColumnChart'} | ${stackedBarChartData}
    ${CHART_TYPES.PIE}         | ${GlColumnChart}        | ${'GlColumnChart'}        | ${barChartData}
  `('when chart is loaded', ({ type, component, name, data }) => {
    let chartComponent;

    beforeEach(() => {
      createWrapper({
        props: {
          type,
          data,
        },
      });

      chartComponent = findChart(component);
    });

    it(`when ${type} is passed: displays the ${name} chart in container and not the loader`, () => {
      expect(wrapper.findComponent(ChartSkeletonLoader).exists()).toBe(false);
      expect(chartComponent.exists()).toBe(true);
    });

    it('should have cursor property set to `auto`', () => {
      expect(chartComponent.props('option')).toEqual(
        expect.objectContaining({
          cursor: 'auto',
        }),
      );
    });

    it('should not drill down when clicking on chart item', async () => {
      chartComponent.vm.$emit('chartItemClicked', chartDataSeriesParams);

      await nextTick();

      expect(visitUrl).not.toHaveBeenCalled();
    });
  });

  describe('when chart receives an error', () => {
    const error = 'my error';

    beforeEach(() => {
      createWrapper({
        props: {
          data: {},
          error,
        },
      });
    });

    it('displays info about the error', () => {
      expect(wrapper.findComponent(ChartSkeletonLoader).exists()).toBe(false);
      expect(wrapper.findComponent(InsightsChartError).exists()).toBe(true);
    });
  });

  describe('when chart supports drilling down', () => {
    const dataSourceType = ISSUABLE_TYPES.ISSUE;

    const supportedChartProps = {
      type: CHART_TYPES.STACKED_BAR,
      data: stackedBarChartData,
      dataSourceType,
    };

    const { groupPathSuffix, projectPathSuffix } = INSIGHTS_DRILLTHROUGH_PATH_SUFFIXES[
      dataSourceType
    ];

    describe.each(INSIGHTS_CHARTS_SUPPORT_DRILLDOWN)('`%s` chart', (chartTitle) => {
      beforeEach(() => {
        createWrapper({
          props: { title: chartTitle, ...supportedChartProps },
        });
      });

      it('should set correct hover interaction properties', () => {
        expect(findChart(GlStackedColumnChart).props('option')).toEqual(
          expect.objectContaining({
            cursor: 'pointer',
            emphasis: {
              focus: 'series',
            },
          }),
        );
      });

      it('should not drill down when clicking on `undefined` chart item', async () => {
        findChart(GlStackedColumnChart).vm.$emit(
          'chartItemClicked',
          chartUndefinedDataSeriesParams,
        );

        await nextTick();

        expect(visitUrl).not.toHaveBeenCalled();
      });

      it.each`
        isProject | relativeUrlRoot | fullPath       | pathSuffix
        ${false}  | ${'/'}          | ${groupPath}   | ${groupPathSuffix}
        ${true}   | ${'/'}          | ${projectPath} | ${projectPathSuffix}
        ${false}  | ${'/path'}      | ${groupPath}   | ${groupPathSuffix}
        ${true}   | ${'/path'}      | ${projectPath} | ${projectPathSuffix}
      `(
        'should drill down to the correct URL when clicking on a chart item',
        async ({ isProject, relativeUrlRoot, fullPath, pathSuffix }) => {
          const {
            params: { seriesName },
          } = chartDataSeriesParams;
          const rootPath = relativeUrlRoot === '/' ? '' : relativeUrlRoot;
          const namespacePath = isProject ? fullPath : `groups/${fullPath}`;
          const expectedDrillDownUrl = `${rootPath}/${namespacePath}/${pathSuffix}?label_name=${seriesName}`;

          gon.relative_url_root = relativeUrlRoot;

          createWrapper({
            props: { title: chartTitle, ...supportedChartProps },
            provide: { isProject, fullPath },
          });

          findChart(GlStackedColumnChart).vm.$emit('chartItemClicked', chartDataSeriesParams);

          await nextTick();

          expect(visitUrl).toHaveBeenCalledTimes(1);
          expect(visitUrl).toHaveBeenCalledWith(expectedDrillDownUrl);
        },
      );
    });
  });
});

import { GlPopover, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import MetricTableCell from 'ee/analytics/dashboards/components/metric_table_cell.vue';

describe('Metric table cell', () => {
  let wrapper;

  const identifier = 'issues';
  const metricLabel = 'Issues created';
  const groupRequestPath = 'groups/test';
  const groupMetricPath = '-/issues_analytics';
  const projectRequestPath = 'test/project';
  const projectMetricPath = '-/analytics/issues_analytics';
  const filterLabels = ['frontend', 'UX'];
  const labelParams = '?label_name[]=frontend&label_name[]=UX';

  const createWrapper = (props = {}) => {
    wrapper = mountExtended(MetricTableCell, {
      propsData: {
        identifier,
        requestPath: groupRequestPath,
        isProject: false,
        ...props,
      },
    });
  };

  const findMetricLabel = () => wrapper.findByTestId('metric_label');
  const findInfoIcon = () => wrapper.findByTestId('info_icon');
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findPopoverLink = () => wrapper.findComponent(GlPopover).findComponent(GlLink);

  describe('drill-down link', () => {
    describe.each`
      isProject | relativeUrlRoot | requestPath           | metricPath
      ${false}  | ${'/'}          | ${groupRequestPath}   | ${groupMetricPath}
      ${true}   | ${'/'}          | ${projectRequestPath} | ${projectMetricPath}
      ${false}  | ${'/path'}      | ${groupRequestPath}   | ${groupMetricPath}
      ${true}   | ${'/path'}      | ${projectRequestPath} | ${projectMetricPath}
    `(
      'when isProject=$isProject and relativeUrlRoot=$relativeUrlRoot',
      ({ isProject, relativeUrlRoot, requestPath, metricPath }) => {
        const rootPath = relativeUrlRoot === '/' ? '' : relativeUrlRoot;
        const metricUrl = `${rootPath}/${requestPath}/${metricPath}`;

        beforeEach(() => {
          gon.relative_url_root = relativeUrlRoot;
        });

        describe('default', () => {
          beforeEach(() => {
            createWrapper({ identifier, requestPath, isProject });
          });

          it('should render the correct link text', () => {
            expect(findMetricLabel().text()).toBe(metricLabel);
          });

          it('should render the correct link URL', () => {
            expect(findMetricLabel().attributes('href')).toBe(metricUrl);
          });
        });

        describe('with filter labels', () => {
          beforeEach(() => {
            createWrapper({ identifier, requestPath, isProject, filterLabels });
          });

          it(`should append filter labels params to the link's URL`, () => {
            const expectedUrl = `${metricUrl}${labelParams}`;

            expect(findMetricLabel().attributes('href')).toBe(expectedUrl);
          });
        });
      },
    );

    it('should emit `drill-down-clicked` event when clicked', () => {
      createWrapper();

      findMetricLabel().vm.$emit('click');

      expect(wrapper.emitted('drill-down-clicked')).toHaveLength(1);
    });
  });

  describe('popover', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows the popover when the info icon is clicked', () => {
      expect(findPopover().props('target')).toBe(findInfoIcon().attributes('id'));
    });

    it('renders popover content based on the metric identifier', () => {
      expect(findPopover().props('title')).toBe(metricLabel);
      expect(findPopover().text()).toContain('Number of new issues created.');
      expect(findPopoverLink().attributes('href')).toBe('/help/user/analytics/issue_analytics');
      expect(findPopoverLink().text()).toBe(MetricTableCell.i18n.docsLabel);
    });
  });
});

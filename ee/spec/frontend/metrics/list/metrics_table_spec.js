import { GlTable, GlLabel } from '@gitlab/ui';
import MetricsTable from 'ee/metrics/list/metrics_table.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { mockMetrics } from './mock_data';

describe('MetricsTable', () => {
  let wrapper;

  const mountComponent = ({ metrics = mockMetrics } = {}) => {
    wrapper = mountExtended(MetricsTable, {
      propsData: {
        metrics,
      },
    });
  };

  const getRows = () => wrapper.findComponent(GlTable).findAll(`[data-testid="metric-row"]`);
  const getRow = (idx) => getRows().at(idx);

  const clickRow = (idx) => getRow(idx).trigger('click');

  it('renders metrics as table', () => {
    mountComponent();

    const rows = getRows();
    expect(rows.length).toBe(mockMetrics.length);
    mockMetrics.forEach((m, i) => {
      const row = getRows().at(i);
      expect(row.find(`[data-testid="metric-name"]`).text()).toBe(m.name);
      expect(row.find(`[data-testid="metric-description"]`).text()).toBe(m.description);
      expect(row.find(`[data-testid="metric-type"]`).text()).toBe(m.type);
    });
  });

  describe('label', () => {
    it.each([
      ['Sum', '#6699cc'],
      ['Gauge', '#cd5b45'],
      ['Histogram', '#009966'],
      ['ExponentialHistogram', '#ed9121'],
      ['unknown', '#808080'],
    ])('sets the proper label when metric type is %s', (type, expectedColor) => {
      mountComponent({
        metrics: [{ name: 'a metric', description: 'a description', type }],
      });
      const label = wrapper.findComponent(GlLabel);
      expect(label.props('backgroundColor')).toBe(expectedColor);
      expect(label.props('title')).toBe(type);
    });
  });

  it('renders the empty state when no metrics are provided', () => {
    mountComponent({ metrics: [] });

    expect(getRows().length).toBe(1);

    expect(getRows().at(0).text()).toContain('No results found');
  });

  it('emits metric-clicked on row-clicked', async () => {
    mountComponent();

    await clickRow(0);

    expect(wrapper.emitted('metric-clicked')[0]).toEqual([
      { metricId: mockMetrics[0].name, clickEvent: expect.any(MouseEvent) },
    ]);
  });
});

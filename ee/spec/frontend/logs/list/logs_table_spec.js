import { GlTable, GlLabel } from '@gitlab/ui';
import LogsTable from 'ee/logs/list/logs_table.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { mockLogs } from './mock_data';

describe('LogsTable', () => {
  let wrapper;

  const mountComponent = ({ logs = mockLogs } = {}) => {
    wrapper = mountExtended(LogsTable, {
      propsData: {
        logs,
      },
    });
  };

  const getRows = () => wrapper.findComponent(GlTable).findAll(`[data-testid="log-row"]`);

  it('renders logs as table', () => {
    mountComponent();

    const rows = getRows();
    expect(rows.length).toBe(mockLogs.length);
    mockLogs.forEach((m, i) => {
      const row = getRows().at(i);
      expect(row.find(`[data-testid="log-timestamp"]`).text()).toBe(m.timestamp);
      expect(row.find(`[data-testid="log-service"]`).text()).toBe(m.service_name);
      expect(row.find(`[data-testid="log-message"]`).text()).toBe(m.body);
    });
  });

  describe('label', () => {
    it.each([
      [1, 'Trace', '#808080'],
      [5, 'Debug', '#808080'],
      [9, 'Info', '#808080'],
      [13, 'Warning', '#ed9121'],
      [17, 'Error', '#dc143c'],
      [21, 'Fatal', '#c21e56'],
      [100, 'Debug', '#808080'],
    ])('sets the proper label when log severity is %d', (severity, title, color) => {
      mountComponent({
        logs: [{ severity_number: severity }],
      });
      const label = wrapper.findComponent(GlLabel);
      expect(label.props('backgroundColor')).toBe(color);
      expect(label.props('title')).toBe(title);
    });
  });

  it('renders the empty state when no logs are provided', () => {
    mountComponent({ logs: [] });

    expect(getRows().length).toBe(1);

    const row = getRows().at(0);
    expect(row.text()).toContain('No logs to display');

    const link = row.findComponent({ name: 'GlLink' });
    expect(link.text()).toBe('Check again');

    link.trigger('click');
    expect(wrapper.emitted('reload')).toHaveLength(1);
  });
});

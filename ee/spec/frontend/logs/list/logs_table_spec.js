import { GlTable, GlLabel } from '@gitlab/ui';
import { nextTick } from 'vue';
import LogsTable from 'ee/logs/list/logs_table.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { formatDate } from '~/lib/utils/datetime/date_format_utility';
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
  const getRow = (idx) => getRows().at(idx);
  const clickRow = async (idx) => {
    getRow(idx).trigger('click');
    await nextTick();
  };

  it('renders logs as table', () => {
    mountComponent();

    const rows = getRows();
    expect(rows.length).toBe(mockLogs.length);
    mockLogs.forEach((m, i) => {
      const row = getRows().at(i);
      expect(row.find(`[data-testid="log-timestamp"]`).text()).toBe(formatDate(m.timestamp));
      expect(row.find(`[data-testid="log-service"]`).text()).toBe(m.service_name);
      expect(row.find(`[data-testid="log-message"]`).text()).toBe(m.body);
    });
  });

  describe('label', () => {
    it.each([
      [1, 'Trace', '#a4a3a8'],
      [5, 'Debug', '#a4a3a8'],
      [9, 'Info', '#428fdc'],
      [13, 'Warning', '#e9be74'],
      [17, 'Error', '#dd2b0e'],
      [21, 'Fatal', '#dd2b0e'],
      [100, 'Debug', '#a4a3a8'],
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

  it('emits log-selected on row-clicked', async () => {
    mountComponent();

    await clickRow(0);
    expect(wrapper.emitted('log-selected')[0]).toEqual([{ fingerprint: mockLogs[0].fingerprint }]);
  });
});

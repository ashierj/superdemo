import { nextTick } from 'vue';
import { GlTable } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import TracingTableList from 'ee/tracing/components/tracing_table_list.vue';

describe('TracingTableList', () => {
  let wrapper;
  const mockTraces = [
    {
      timestamp: '2023-07-10T15:02:30.677538Z',
      service_name: 'tracegen',
      operation: 'lets-go',
      duration_nano: 1500000,
      trace_id: 'trace-1',
    },
    {
      timestamp: '2023-08-11T16:03:40.577538Z',
      service_name: 'tracegen-2',
      operation: 'lets-go-2',
      duration_nano: 2000000,
      trace_id: 'trace-2',
    },
  ];

  const expectedTraces = [
    {
      timestamp: 'Jul 10, 2023 3:02pm UTC',
      service_name: 'tracegen',
      operation: 'lets-go',
      duration: '1.50 ms',
      trace_id: 'trace-1',
    },
    {
      timestamp: 'Aug 11, 2023 4:03pm UTC',
      service_name: 'tracegen-2',
      operation: 'lets-go-2',
      duration: '2.00 ms',
      trace_id: 'trace-2',
    },
  ];

  const mountComponent = ({ traces = mockTraces, highlightedTraceId } = {}) => {
    wrapper = mountExtended(TracingTableList, {
      propsData: {
        traces,
        highlightedTraceId,
      },
    });
  };

  const getRows = () => wrapper.findComponent(GlTable).findAll(`[data-testid="trace-row"]`);
  const getRow = (idx) => getRows().at(idx);

  const clickRow = async (idx) => {
    getRow(idx).trigger('click');
    await nextTick();
  };

  it('renders traces as table', () => {
    mountComponent();

    const rows = getRows();
    expect(rows.length).toBe(mockTraces.length);
    mockTraces.forEach((_, i) => {
      const row = getRows().at(i);
      const trace = expectedTraces[i];
      expect(row.find(`[data-testid="trace-timestamp"]`).text()).toBe(trace.timestamp);
      expect(row.find(`[data-testid="trace-service"]`).text()).toBe(trace.service_name);
      expect(row.find(`[data-testid="trace-operation"]`).text()).toBe(trace.operation);
      expect(row.find(`[data-testid="trace-duration"]`).text()).toBe(trace.duration);
    });
  });

  it('emits trace-clicked on row-clicked', async () => {
    mountComponent();

    await clickRow(0);
    expect(wrapper.emitted('trace-clicked')[0]).toEqual([
      { traceId: mockTraces[0].trace_id, clickEvent: expect.any(MouseEvent) },
    ]);
  });

  it('renders the empty state when no traces are provided', () => {
    mountComponent({ traces: [] });

    expect(getRows().length).toBe(1);

    expect(getRows().at(0).text()).toContain('No results found');
  });

  it('sets the correct variant when a trace is highlighted', () => {
    mountComponent({ highlightedTraceId: 'trace-2' });

    expect(getRow(1).classes()).toContain('gl-bg-t-gray-a-08');
    expect(getRow(0).classes()).not.toContain('gl-bg-t-gray-a-08');
  });
});

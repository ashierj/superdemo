import { GlLoadingIcon } from '@gitlab/ui';
import LogsTable from 'ee/logs/list/logs_table.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LogsList from 'ee/logs/list/logs_list.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { mockLogs } from './mock_data';

jest.mock('~/alert');

describe('LogsList', () => {
  let wrapper;
  let observabilityClientMock;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findLogsTable = () => wrapper.findComponent(LogsTable);

  const mountComponent = async () => {
    wrapper = shallowMountExtended(LogsList, {
      propsData: {
        observabilityClient: observabilityClientMock,
      },
    });
    await waitForPromises();
  };

  beforeEach(() => {
    observabilityClientMock = {
      fetchLogs: jest.fn().mockResolvedValue(mockLogs),
    };
  });

  it('renders the loading indicator while fetching logs', () => {
    mountComponent();

    expect(findLoadingIcon().exists()).toBe(true);
    expect(findLogsTable().exists()).toBe(false);
    expect(observabilityClientMock.fetchLogs).toHaveBeenCalled();
  });

  it('renders the LogsTable when fetching logs is done', async () => {
    await mountComponent();

    expect(findLoadingIcon().exists()).toBe(false);
    expect(findLogsTable().exists()).toBe(true);
    expect(findLogsTable().props('logs')).toEqual(mockLogs);
  });

  it('calls fetchLogs method when LogsTable emits reload event', async () => {
    await mountComponent();

    observabilityClientMock.fetchLogs.mockClear();

    findLogsTable().vm.$emit('reload');

    expect(observabilityClientMock.fetchLogs).toHaveBeenCalledTimes(1);
  });

  it('if fetchLogs fails, it renders an alert and empty list', async () => {
    observabilityClientMock.fetchLogs.mockRejectedValue('error');

    await mountComponent();

    expect(createAlert).toHaveBeenLastCalledWith({ message: 'Failed to load logs.' });
    expect(findLogsTable().exists()).toBe(true);
    expect(findLogsTable().props('logs')).toEqual([]);
  });
});

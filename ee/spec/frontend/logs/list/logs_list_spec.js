import { GlLoadingIcon } from '@gitlab/ui';
import LogsTable from 'ee/logs/list/logs_table.vue';
import LogsDrawer from 'ee/logs/list/logs_drawer.vue';
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

  const findDrawer = () => wrapper.findComponent(LogsDrawer);
  const isDrawerOpen = () => findDrawer().props('open');
  const getDrawerSelectedLog = () => findDrawer().props('log');

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

  describe('details drawer', () => {
    beforeEach(async () => {
      await mountComponent();
    });
    it('renders the details drawer initially closed', () => {
      expect(findDrawer().exists()).toBe(true);
      expect(isDrawerOpen()).toBe(false);
      expect(getDrawerSelectedLog()).toBe(null);
    });

    const selectLog = (logIndex) =>
      findLogsTable().vm.$emit('log-selected', { fingerprint: mockLogs[logIndex].fingerprint });

    it('opens the drawer and set the selected log, upond selection', async () => {
      await selectLog(1);

      expect(isDrawerOpen()).toBe(true);
      expect(getDrawerSelectedLog()).toEqual(mockLogs[1]);
    });

    it('closes the drawer upon receiving the close event', async () => {
      await selectLog(1);

      await findDrawer().vm.$emit('close');

      expect(isDrawerOpen()).toBe(false);
      expect(getDrawerSelectedLog()).toBe(null);
    });

    it('closes the drawer if the same log is selected', async () => {
      await selectLog(1);

      expect(isDrawerOpen()).toBe(true);

      await selectLog(1);

      expect(isDrawerOpen()).toBe(false);
    });

    it('changes the selected log and keeps the drawer open, upon selecting a different log', async () => {
      await selectLog(1);

      expect(isDrawerOpen()).toBe(true);

      await selectLog(2);

      expect(isDrawerOpen()).toBe(true);
      expect(getDrawerSelectedLog()).toEqual(mockLogs[2]);
    });

    it('handles invalid logs', async () => {
      await findLogsTable().vm.$emit('log-selected', { fingerprint: 'i-do-not-exist' });

      expect(isDrawerOpen()).toBe(false);
      expect(getDrawerSelectedLog()).toBe(null);
    });
  });
});

import { GlButton } from '@gitlab/ui';

import AdminRunnersDashboardApp from 'ee/ci/runner/admin_runners_dashboard/admin_runners_dashboard_app.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import RunnerDashboardStatOnline from 'ee/ci/runner/components/runner_dashboard_stat_online.vue';
import RunnerDashboardStatOffline from 'ee/ci/runner/components/runner_dashboard_stat_offline.vue';
import RunnerUsage from 'ee/ci/runner/components/runner_usage.vue';
import RunnerJobFailures from 'ee/ci/runner/components/runner_job_failures.vue';
import RunnerActiveList from 'ee/ci/runner/components/runner_active_list.vue';
import RunnerWaitTimes from 'ee/ci/runner/components/runner_wait_times.vue';

const mockAdminRunnersPath = '/runners/list';
const mockNewRunnerPath = '/runners/new';

describe('AdminRunnersDashboardApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(AdminRunnersDashboardApp, {
      propsData: {
        adminRunnersPath: mockAdminRunnersPath,
        newRunnerPath: mockNewRunnerPath,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('shows title and actions', () => {
    const [listBtn, newBtn] = wrapper.findAllComponents(GlButton).wrappers;

    expect(listBtn.text()).toBe('View runners list');
    expect(listBtn.attributes('href')).toBe(mockAdminRunnersPath);

    expect(newBtn.text()).toBe('New instance runner');
    expect(newBtn.attributes('href')).toBe(mockNewRunnerPath);
  });

  it('shows dashboard panels', () => {
    expect(wrapper.findComponent(RunnerDashboardStatOnline).exists()).toBe(true);
    expect(wrapper.findComponent(RunnerDashboardStatOffline).exists()).toBe(true);
    expect(wrapper.findComponent(RunnerUsage).exists()).toBe(true);
    expect(wrapper.findComponent(RunnerJobFailures).exists()).toBe(true);
    expect(wrapper.findComponent(RunnerActiveList).exists()).toBe(true);
    expect(wrapper.findComponent(RunnerWaitTimes).exists()).toBe(true);
  });
});

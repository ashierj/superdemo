import { GlIcon } from '@gitlab/ui';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { I18N_STATUS_OFFLINE, STATUS_OFFLINE } from '~/ci/runner/constants';
import RunnerDashboardStat from 'ee/ci/runner/components/runner_dashboard_stat.vue';

import RunnerDashboardStatOffline from 'ee/ci/runner/components/runner_dashboard_stat_offline.vue';

describe('RunnerDashboardStatOffline', () => {
  let wrapper;

  const findRunnerDashboardStat = () => wrapper.findComponent(RunnerDashboardStat);
  const findIcon = () => wrapper.findComponent(GlIcon);

  const createComponent = (options = {}) => {
    wrapper = shallowMountExtended(RunnerDashboardStatOffline, {
      stubs: {
        RunnerDashboardStat: stubComponent(RunnerDashboardStat, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
      },
      ...options,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('shows offline runners', () => {
    expect(findRunnerDashboardStat().props('variables')).toEqual({ status: STATUS_OFFLINE });
  });

  it('shows icon and title', () => {
    expect(findIcon().props()).toMatchObject({
      name: 'status-waiting',
      size: 12,
    });

    expect(wrapper.findByText(I18N_STATUS_OFFLINE).exists()).toBe(true);
  });
});

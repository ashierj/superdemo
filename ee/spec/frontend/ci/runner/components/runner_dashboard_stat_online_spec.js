import { GlIcon } from '@gitlab/ui';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { I18N_STATUS_ONLINE, STATUS_ONLINE } from '~/ci/runner/constants';
import RunnerDashboardStat from 'ee/ci/runner/components/runner_dashboard_stat.vue';

import RunnerDashboardStatOnline from 'ee/ci/runner/components/runner_dashboard_stat_online.vue';

describe('RunnerDashboardStatOnline', () => {
  let wrapper;

  const findRunnerDashboardStat = () => wrapper.findComponent(RunnerDashboardStat);
  const findIcon = () => wrapper.findComponent(GlIcon);

  const createComponent = (options = {}) => {
    wrapper = shallowMountExtended(RunnerDashboardStatOnline, {
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

  it('shows online runners', () => {
    expect(findRunnerDashboardStat().props('variables')).toEqual({ status: STATUS_ONLINE });
  });

  it('shows icon and title', () => {
    expect(findIcon().props()).toMatchObject({
      name: 'status-active',
      size: 12,
    });

    expect(wrapper.findByText(I18N_STATUS_ONLINE).exists()).toBe(true);
  });
});

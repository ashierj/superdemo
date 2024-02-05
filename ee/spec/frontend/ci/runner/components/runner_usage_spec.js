import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createAlert } from '~/alert';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { INSTANCE_TYPE } from '~/ci/runner/constants';
import RunnerUsageExportMutation from 'ee/ci/runner/graphql/performance/runner_usage_export.mutation.graphql';

import RunnerUsage from 'ee/ci/runner/components/runner_usage.vue';

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/sentry/sentry_browser_wrapper');

describe('RunnerUsage', () => {
  let wrapper;
  let mockToast;
  let runnerUsageExportHandler;

  const findButton = () => wrapper.findComponent(GlButton);
  const clickButton = async () => {
    findButton().vm.$emit('click');
    await waitForPromises();
  };

  const createWrapper = ({ provide } = {}) => {
    confirmAction.mockResolvedValue(true);

    runnerUsageExportHandler = jest.fn();
    mockToast = jest.fn();

    wrapper = shallowMount(RunnerUsage, {
      apolloProvider: createMockApollo([[RunnerUsageExportMutation, runnerUsageExportHandler]]),
      mocks: {
        $toast: { show: mockToast },
      },
      provide: {
        clickhouseCiAnalyticsAvailable: true,
        ...provide,
      },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  it('renders button', () => {
    expect(findButton().text()).toBe('Export as CSV');
  });

  it('does not render when clickhouseCiAnalytics is disabled', () => {
    createWrapper({
      provide: { clickhouseCiAnalyticsAvailable: false },
    });

    expect(wrapper.html()).toBe('');
  });

  it('calls mutation on button click', async () => {
    runnerUsageExportHandler.mockReturnValue(new Promise(() => {}));

    await clickButton();

    expect(runnerUsageExportHandler).toHaveBeenCalledWith({
      input: { type: INSTANCE_TYPE },
    });
    expect(findButton().props('loading')).toBe(true);
  });

  describe('when user does not confirm', () => {
    beforeEach(() => {
      confirmAction.mockReturnValue(false);
    });

    it('does not call mutation', async () => {
      await clickButton();

      expect(runnerUsageExportHandler).not.toHaveBeenCalled();
      expect(findButton().props('loading')).toBe(false);
    });
  });

  it('handles successful result', async () => {
    runnerUsageExportHandler.mockResolvedValue({
      data: { runnersExportUsage: { errors: [] } },
    });

    await clickButton();

    expect(findButton().props('loading')).toBe(false);
    expect(mockToast).toHaveBeenCalledWith(expect.stringContaining('CSV export has started'));
  });

  describe('when an error occurs', () => {
    it('handles network error', async () => {
      runnerUsageExportHandler.mockRejectedValue(new Error('Network error'));

      await clickButton();

      expect(findButton().props('loading')).toBe(false);
      expect(createAlert).toHaveBeenCalledWith({
        message: expect.stringContaining('Something went wrong'),
      });

      expect(Sentry.captureException).toHaveBeenCalledWith(new Error('Network error'));
    });

    it('handles graphql error', async () => {
      runnerUsageExportHandler.mockResolvedValue({
        data: { runnersExportUsage: { errors: ['Error 1', 'Error 2'] } },
      });

      await clickButton();

      expect(findButton().props('loading')).toBe(false);
      expect(createAlert).toHaveBeenCalledWith({
        message: expect.stringContaining('Something went wrong'),
      });

      expect(Sentry.captureException).toHaveBeenCalledWith(new Error('Error 1 Error 2'));
    });
  });
});

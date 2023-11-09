import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlSkeletonLoader, GlSprintf } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  getProjectsUsageDataResponse,
  getProjectUsage,
} from 'ee_jest/usage_quotas/product_analytics/graphql/mock_data';
import { useFakeDate } from 'helpers/fake_date';

import getGroupCurrentAndPrevProductAnalyticsUsage from 'ee/usage_quotas/product_analytics/graphql/queries/get_group_current_and_prev_product_analytics_usage.query.graphql';
import ProductAnalyticsGroupUsageChart from 'ee/usage_quotas/product_analytics/components/product_analytics_group_usage_chart.vue';

Vue.use(VueApollo);

jest.mock('~/sentry/sentry_browser_wrapper');

describe('ProductAnalyticsGroupUsageChart', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findError = () => wrapper.findComponent(GlAlert);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findChart = () => wrapper.findComponent(GlAreaChart);
  const findLearnMoreLink = () => wrapper.findByTestId('product-analytics-usage-quota-learn-more');

  const mockProjectsUsageDataHandler = jest.fn();

  const createComponent = () => {
    const mockApollo = createMockApollo([
      [getGroupCurrentAndPrevProductAnalyticsUsage, mockProjectsUsageDataHandler],
    ]);

    wrapper = shallowMountExtended(ProductAnalyticsGroupUsageChart, {
      apolloProvider: mockApollo,
      provide: {
        namespacePath: 'some-group',
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  afterEach(() => {
    mockProjectsUsageDataHandler.mockReset();
  });

  it('renders a section header', () => {
    createComponent();

    expect(wrapper.text()).toContain('Usage by month');
    expect(findLearnMoreLink().attributes('href')).toBe(
      '/help/user/product_analytics/index#product-analytics-usage-quota',
    );
  });

  describe('when fetching data', () => {
    const mockNow = '2023-01-15T12:00:00Z';
    useFakeDate(mockNow);

    it('requests data from the current and previous months', () => {
      createComponent();

      expect(mockProjectsUsageDataHandler).toHaveBeenCalledWith({
        namespacePath: 'some-group',
        currentMonth: 1,
        currentYear: 2023,
        previousMonth: 12,
        previousYear: 2022,
      });
    });

    describe('while loading', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not render an error', () => {
        expect(findError().exists()).toBe(false);
      });

      it('renders the loading state', () => {
        expect(findSkeletonLoader().exists()).toBe(true);
      });

      it('does not render the chart', () => {
        expect(findChart().exists()).toBe(false);
      });
    });

    describe('and there is an error', () => {
      const error = new Error('oh no!');

      beforeEach(() => {
        mockProjectsUsageDataHandler.mockRejectedValue(error);
        createComponent();
        return waitForPromises();
      });

      it('does not render the loading state', () => {
        expect(findSkeletonLoader().exists()).toBe(false);
      });

      it('does not render the chart', () => {
        expect(findChart().exists()).toBe(false);
      });

      it('renders an error', () => {
        expect(findError().text()).toContain(
          'Something went wrong while loading product analytics usage data. Refresh the page to try again.',
        );
      });

      it('captures the error in Sentry', () => {
        expect(Sentry.captureException).toHaveBeenCalledTimes(1);
        expect(Sentry.captureException.mock.calls[0][0]).toEqual(error);
      });
    });

    describe('and the data has loaded', () => {
      describe.each`
        scenario                                        | currentProjects                                                         | previousProjects
        ${'with no projects'}                           | ${[]}                                                                   | ${[]}
        ${'with no product analytics enabled projects'} | ${[getProjectUsage({ id: 1, name: 'not onboarded', numEvents: null })]} | ${[getProjectUsage({ id: 1, name: 'not onboarded', numEvents: null })]}
      `('$scenario', ({ currentProjects, previousProjects }) => {
        beforeEach(() => {
          mockProjectsUsageDataHandler.mockResolvedValue({
            data: getProjectsUsageDataResponse(currentProjects, previousProjects),
          });
          createComponent();
          return waitForPromises();
        });

        it('does not render an error', () => {
          expect(findError().exists()).toBe(false);
        });

        it('does not render the loading state', () => {
          expect(findSkeletonLoader().exists()).toBe(false);
        });

        it('emits "no-projects" event', () => {
          expect(wrapper.emitted('no-projects')).toHaveLength(1);
        });
      });

      describe('with one project', () => {
        beforeEach(() => {
          mockProjectsUsageDataHandler.mockResolvedValue({ data: getProjectsUsageDataResponse() });
          createComponent();
          return waitForPromises();
        });

        it('does not render an error', () => {
          expect(findError().exists()).toBe(false);
        });

        it('does not render the loading state', () => {
          expect(findSkeletonLoader().exists()).toBe(false);
        });

        it('renders the chart', () => {
          expect(findChart().props()).toMatchObject({
            data: [
              {
                name: 'Analytics events by month',
                data: [
                  ['Dec 2022', 1234],
                  ['Jan 2023', 9876],
                ],
              },
            ],
          });
        });
      });

      describe('with many projects', () => {
        beforeEach(() => {
          mockProjectsUsageDataHandler.mockResolvedValue({
            data: getProjectsUsageDataResponse(
              [
                getProjectUsage({ id: 1, name: 'onboarded1', numEvents: 1 }),
                getProjectUsage({ id: 2, name: 'onboarded2', numEvents: 1 }),
                getProjectUsage({ id: 3, name: 'onboarded3', numEvents: 1 }),
              ],
              [
                getProjectUsage({ id: 1, name: 'onboarded1', numEvents: 10 }),
                getProjectUsage({ id: 2, name: 'onboarded2', numEvents: 20 }),
                getProjectUsage({ id: 3, name: 'onboarded3', numEvents: 30 }),
              ],
            ),
          });
          createComponent();
          return waitForPromises();
        });

        it('renders the chart with correctly summed counts', () => {
          expect(findChart().props()).toMatchObject({
            data: [
              {
                name: 'Analytics events by month',
                data: [
                  ['Dec 2022', 60],
                  ['Jan 2023', 3],
                ],
              },
            ],
          });
        });
      });
    });
  });
});

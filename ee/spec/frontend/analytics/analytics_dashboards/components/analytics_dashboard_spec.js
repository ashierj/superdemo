import { GlLoadingIcon } from '@gitlab/ui';
import { HTTP_STATUS_CREATED, HTTP_STATUS_FORBIDDEN } from '~/lib/utils/http_status';
import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import AnalyticsDashboard from 'ee/analytics/analytics_dashboards/components/analytics_dashboard.vue';
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import { dashboard } from 'ee_jest/vue_shared/components/customizable_dashboard/mock_data';
import { buildDefaultDashboardFilters } from 'ee/vue_shared/components/customizable_dashboard/utils';
import {
  getCustomDashboard,
  getProductAnalyticsVisualizationList,
  getProductAnalyticsVisualization,
  saveCustomDashboard,
} from 'ee/analytics/analytics_dashboards/api/dashboards_api';
import { TEST_CUSTOM_DASHBOARDS_PROJECT, TEST_CUSTOM_DASHBOARD } from '../mock_data';

jest.mock('~/alert');
jest.mock('ee/analytics/analytics_dashboards/api/dashboards_api');

const showToast = jest.fn();

describe('AnalyticsDashboard', () => {
  let wrapper;

  const findDashboard = () => wrapper.findComponent(CustomizableDashboard);
  const findLoader = () => wrapper.findComponent(GlLoadingIcon);

  const mockSaveDashboardImplementation = async (responseCallback) => {
    saveCustomDashboard.mockImplementation(responseCallback);

    await waitForPromises();

    findDashboard().vm.$emit('save', 'custom_dashboard', {});
  };

  beforeEach(() => {
    getCustomDashboard.mockImplementation(() => TEST_CUSTOM_DASHBOARD);
    getProductAnalyticsVisualizationList.mockImplementation(() => []);
    getProductAnalyticsVisualization.mockImplementation(() => TEST_CUSTOM_DASHBOARD);
  });

  const createWrapper = (data = {}, routeId) => {
    const mocks = {
      $toast: {
        show: showToast,
      },
      $route: {
        params: {
          id: routeId || '',
        },
      },
      $router: {
        replace() {},
        push() {},
      },
    };

    wrapper = shallowMountExtended(AnalyticsDashboard, {
      data() {
        return {
          dashboard: null,
          ...data,
        };
      },
      stubs: ['router-link', 'router-view'],
      mocks,
      provide: {
        customDashboardsProject: TEST_CUSTOM_DASHBOARDS_PROJECT,
      },
    });
  };

  describe('when mounted', () => {
    it('should render with mock dashboard with filter properties', async () => {
      createWrapper({
        dashboard,
      });

      expect(getCustomDashboard).toHaveBeenCalledWith('', TEST_CUSTOM_DASHBOARDS_PROJECT);

      expect(findDashboard().props()).toMatchObject({
        initialDashboard: dashboard,
        defaultFilters: buildDefaultDashboardFilters(''),
        dateRangeLimit: 0,
        showDateRangeFilter: true,
        syncUrlFilters: true,
      });
    });

    it('should render the loading icon while fetching data', async () => {
      createWrapper({}, 'dashboard_audience');

      expect(findLoader().exists()).toBe(true);

      await waitForPromises();

      expect(findLoader().exists()).toBe(false);
    });

    it('should render audience dashboard by id', async () => {
      createWrapper({}, 'dashboard_audience');

      await waitForPromises();

      expect(getCustomDashboard).toHaveBeenCalledTimes(0);
      expect(getProductAnalyticsVisualizationList).toHaveBeenCalledWith(
        TEST_CUSTOM_DASHBOARDS_PROJECT,
      );
      expect(getProductAnalyticsVisualization).toHaveBeenCalledTimes(0);

      expect(findDashboard().exists()).toBe(true);
    });

    it('should render behavior dashboard by id', async () => {
      createWrapper({}, 'dashboard_behavior');

      await waitForPromises();

      expect(getCustomDashboard).toHaveBeenCalledTimes(0);
      expect(getProductAnalyticsVisualizationList).toHaveBeenCalledWith(
        TEST_CUSTOM_DASHBOARDS_PROJECT,
      );
      expect(getProductAnalyticsVisualization).toHaveBeenCalledTimes(0);

      expect(findDashboard().exists()).toBe(true);
    });

    it('should render custom dashboard by id', async () => {
      createWrapper({}, 'custom_dashboard');

      await waitForPromises();

      expect(getCustomDashboard).toHaveBeenCalledWith(
        'custom_dashboard',
        TEST_CUSTOM_DASHBOARDS_PROJECT,
      );
      expect(getProductAnalyticsVisualizationList).toHaveBeenCalledWith(
        TEST_CUSTOM_DASHBOARDS_PROJECT,
      );
      expect(getProductAnalyticsVisualization).toHaveBeenCalledWith(
        'page_views_per_day',
        TEST_CUSTOM_DASHBOARDS_PROJECT,
      );

      expect(findDashboard().exists()).toBe(true);
    });
  });

  describe('when saving', () => {
    it('custom dashboard successfully by id', async () => {
      createWrapper({}, 'custom_dashboard');

      await mockSaveDashboardImplementation(() => ({ status: HTTP_STATUS_CREATED }));

      expect(saveCustomDashboard).toHaveBeenCalledWith(
        'custom_dashboard',
        {},
        TEST_CUSTOM_DASHBOARDS_PROJECT,
      );

      await waitForPromises();

      expect(showToast).toHaveBeenCalledWith('Dashboard was saved successfully');
    });

    it('custom dashboard with an error', async () => {
      createWrapper({}, 'custom_dashboard');

      await mockSaveDashboardImplementation(() => ({ status: HTTP_STATUS_FORBIDDEN }));

      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Error while saving Dashboard!',
      });
    });

    it('custom dashboard with an error thrown', async () => {
      createWrapper({}, 'custom_dashboard');

      const newError = new Error();

      mockSaveDashboardImplementation(() => {
        throw newError;
      });

      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith({
        error: newError,
        message: 'Error while saving Dashboard!',
        reportError: true,
      });
    });
  });
});

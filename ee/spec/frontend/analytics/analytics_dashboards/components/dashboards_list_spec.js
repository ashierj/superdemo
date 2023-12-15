import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import { mockTracking } from 'helpers/tracking_helper';
import ProductAnalyticsOnboarding from 'ee/product_analytics/onboarding/components/onboarding_list_item.vue';
import DashboardsList from 'ee/analytics/analytics_dashboards/components/dashboards_list.vue';
import DashboardListItem from 'ee/analytics/analytics_dashboards/components/list/dashboard_list_item.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { VALUE_STREAMS_DASHBOARD_CONFIG } from 'ee/analytics/dashboards/constants';
import { InternalEvents } from '~/tracking';
import { helpPagePath } from '~/helpers/help_page_helper';
import { createAlert } from '~/alert';
import getAllCustomizableDashboardsQuery from 'ee/analytics/analytics_dashboards/graphql/queries/get_all_customizable_dashboards.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  TEST_COLLECTOR_HOST,
  TEST_TRACKING_KEY,
  TEST_CUSTOM_DASHBOARDS_PROJECT,
  TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE,
  TEST_DASHBOARD_GRAPHQL_EMPTY_SUCCESS_RESPONSE,
  TEST_CUSTOM_GROUP_VSD_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE,
} from '../mock_data';

const mockAlertDismiss = jest.fn();
jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

Vue.use(VueApollo);

describe('DashboardsList', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;
  let trackingSpy;

  const findListItems = () => wrapper.findAllComponents(DashboardListItem);
  const findListLoadingSkeletons = () => wrapper.findAllComponents(GlSkeletonLoader);
  const findProductAnalyticsOnboarding = () => wrapper.findComponent(ProductAnalyticsOnboarding);
  const findPageTitle = () => wrapper.findByTestId('title');
  const findPageDescription = () => wrapper.findByTestId('description');
  const findHelpLink = () => wrapper.findByTestId('help-link');
  const findNewDashboardButton = () => wrapper.findByTestId('new-dashboard-button');
  const findVisualizationDesignerButton = () =>
    wrapper.findByTestId('visualization-designer-button');
  const findConfigureAlert = () => wrapper.findComponent(GlAlert);

  const $router = {
    push: jest.fn(),
  };

  let mockAnalyticsDashboardsHandler = jest.fn();

  const createWrapper = (provided = {}) => {
    trackingSpy = mockTracking(undefined, window.document, jest.spyOn);

    const mockApollo = createMockApollo([
      [getAllCustomizableDashboardsQuery, mockAnalyticsDashboardsHandler],
    ]);

    wrapper = shallowMountExtended(DashboardsList, {
      apolloProvider: mockApollo,
      stubs: {
        RouterLink: true,
      },
      mocks: {
        $router,
      },
      provide: {
        isProject: true,
        isGroup: false,
        collectorHost: TEST_COLLECTOR_HOST,
        trackingKey: TEST_TRACKING_KEY,
        customDashboardsProject: TEST_CUSTOM_DASHBOARDS_PROJECT,
        canConfigureDashboardsProject: true,
        namespaceFullPath: TEST_CUSTOM_DASHBOARDS_PROJECT.fullPath,
        analyticsSettingsPath: '/test/-/settings#foo',
        ...provided,
      },
    });
  };

  afterEach(() => {
    mockAnalyticsDashboardsHandler.mockReset();
  });

  describe('by default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render the page title', () => {
      expect(findPageTitle().text()).toBe('Analytics dashboards');
    });

    it('renders the visualization designer button', () => {
      expect(findVisualizationDesignerButton().exists()).toBe(true);
    });

    it('renders the new dashboard button', () => {
      expect(findNewDashboardButton().exists()).toBe(true);
    });

    it('should render the help link', () => {
      expect(findHelpLink().text()).toBe('Learn more.');
      expect(findHelpLink().attributes('href')).toBe(
        helpPagePath('user/analytics/analytics_dashboards'),
      );
    });

    it('does not render any feature or custom dashboards', () => {
      expect(findListItems()).toHaveLength(0);
    });

    it('should track the dashboard list has been viewed', () => {
      expect(trackingSpy).toHaveBeenCalledWith(
        expect.any(String),
        'user_viewed_dashboard_list',
        expect.any(Object),
      );
    });

    it('fetches the list of dashboards', () => {
      expect(mockAnalyticsDashboardsHandler).toHaveBeenCalledWith({
        fullPath: TEST_CUSTOM_DASHBOARDS_PROJECT.fullPath,
        isGroup: false,
        isProject: true,
      });
    });

    it('renders a loading state', () => {
      expect(findListLoadingSkeletons()).toHaveLength(2);
    });
  });

  describe('for projects', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render the page description', () => {
      expect(findPageDescription().text()).toContain(
        'Dashboards are created by editing the projects dashboard files.',
      );
    });
  });

  describe('for groups', () => {
    describe('when `groupAnalyticsDashboards` FF is disabled', () => {
      beforeEach(() => {
        createWrapper({ isProject: false, isGroup: true });
      });

      it('should render the page description', () => {
        expect(findPageDescription().text()).toContain(
          'Dashboards are created by editing the groups dashboard files.',
        );
      });

      it('should not render the Value streams dashboards link', () => {
        expect(findListItems()).toHaveLength(0);
      });
    });

    describe('when `groupAnalyticsDashboards` FF is enabled', () => {
      beforeEach(() => {
        mockAnalyticsDashboardsHandler = jest
          .fn()
          .mockResolvedValue(TEST_CUSTOM_GROUP_VSD_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE);

        createWrapper({
          isProject: false,
          isGroup: true,
          glFeatures: { groupAnalyticsDashboards: true },
        });
      });

      it('should redirect to the legacy VSD page', async () => {
        await waitForPromises();
        expect(findListItems()).toHaveLength(1);
        expect(findListItems().at(0).props('dashboard')).toMatchObject(
          VALUE_STREAMS_DASHBOARD_CONFIG,
        );
      });
    });

    describe('when `groupAnalyticsDashboards` and `groupAnalyticsDashboardDynamicVsd` feature flags are enabled', () => {
      beforeEach(() => {
        mockAnalyticsDashboardsHandler = jest
          .fn()
          .mockResolvedValue(TEST_CUSTOM_GROUP_VSD_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE);

        createWrapper({
          isProject: false,
          isGroup: true,
          glFeatures: {
            groupAnalyticsDashboards: true,
            groupAnalyticsDashboardDynamicVsd: true,
          },
        });
      });

      it('should render the Value streams dashboards link', async () => {
        await waitForPromises();
        expect(findListItems()).toHaveLength(1);

        const dashboardAttributes = findListItems().at(0).props('dashboard');

        expect(dashboardAttributes).not.toMatchObject(VALUE_STREAMS_DASHBOARD_CONFIG);
        expect(dashboardAttributes).toMatchObject({
          slug: 'value_streams_dashboard',
          title: 'Value Streams Dashboard',
        });
      });
    });
  });

  describe('configure custom dashboards project', () => {
    describe('when user has permission', () => {
      it('shows the custom dashboard setup alert', () => {
        createWrapper({ customDashboardsProject: null, canConfigureDashboardsProject: true });

        expect(findConfigureAlert().exists()).toBe(true);
      });
    });

    describe('when user does not have permission', () => {
      beforeEach(() => {
        createWrapper({ customDashboardsProject: null, canConfigureDashboardsProject: false });
      });

      it('does not show the custom dashboard setup alert', () => {
        expect(findConfigureAlert().exists()).toBe(false);
      });
    });

    describe('when custom dashboards project is falsy', () => {
      beforeEach(() => {
        createWrapper({ customDashboardsProject: null });
      });

      it('does not show the designer buttons', () => {
        expect(findVisualizationDesignerButton().exists()).toBe(false);
        expect(findNewDashboardButton().exists()).toBe(false);
      });
    });
  });

  describe('when the product analytics feature is enabled', () => {
    beforeEach(() => {
      mockAnalyticsDashboardsHandler = jest
        .fn()
        .mockResolvedValue(TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE);

      createWrapper({ features: ['productAnalytics'] });
    });

    it('renders the onboarding component', () => {
      expect(findProductAnalyticsOnboarding().exists()).toBe(true);
    });

    describe('when the onboarding component emits "complete"', () => {
      beforeEach(async () => {
        await waitForPromises();

        findProductAnalyticsOnboarding().vm.$emit('complete');
      });

      it('removes the onboarding component from the DOM', () => {
        expect(findProductAnalyticsOnboarding().exists()).toBe(false);
      });

      it('refetches the list of dashboards', () => {
        expect(findListLoadingSkeletons()).toHaveLength(2);
        expect(mockAnalyticsDashboardsHandler).toHaveBeenCalledTimes(2);
      });
    });

    describe('when the onboarding component emits "error"', () => {
      const message = 'some error';
      const error = new Error(message);

      beforeEach(async () => {
        await waitForPromises();

        findProductAnalyticsOnboarding().vm.$emit('error', error, true, message);
      });

      it('creates an alert for the error', () => {
        expect(createAlert).toHaveBeenCalledWith({
          captureError: true,
          message,
          error,
        });
      });

      it('dimisses the alert when the component is destroyed', async () => {
        wrapper.destroy();

        await nextTick();

        expect(mockAlertDismiss).toHaveBeenCalled();
      });
    });
  });

  describe('when the list of dashboards have been fetched', () => {
    const setupWithResponse = (mockResponseVal) => {
      mockAnalyticsDashboardsHandler = jest.fn().mockResolvedValue(mockResponseVal);

      createWrapper();

      return waitForPromises();
    };

    describe('and there are dashbaords', () => {
      beforeEach(() => {
        return setupWithResponse(TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE);
      });

      it('does not render a loading state', () => {
        expect(findListLoadingSkeletons()).toHaveLength(0);
      });

      it('renders a list item for each custom and feature dashboard', () => {
        const expectedDashboards =
          TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE.data?.project?.customizableDashboards?.nodes;

        expect(findListItems()).toHaveLength(expectedDashboards.length);

        expectedDashboards.forEach(async (dashboard, idx) => {
          const dashboardItem = findListItems().at(idx);
          expect(dashboardItem.props('dashboard')).toEqual(dashboard);
          expect(dashboardItem.attributes()['data-event-tracking']).toBe('user_visited_dashboard');

          InternalEvents.bindInternalEventDocument(dashboardItem.element);
          await dashboardItem.trigger('click');
          await nextTick();

          expect(trackingSpy).toHaveBeenCalledWith(
            expect.any(String),
            'user_visited_dashboard',
            expect.any(Object),
          );
        });
      });
    });

    describe('and the response is empty', () => {
      beforeEach(() => {
        return setupWithResponse(TEST_DASHBOARD_GRAPHQL_EMPTY_SUCCESS_RESPONSE);
      });

      it('does not render a loading state', () => {
        expect(findListLoadingSkeletons()).toHaveLength(0);
      });

      it('does not render any list items', () => {
        expect(findListItems()).toHaveLength(0);
      });
    });
  });

  describe('when an error occured while fetching the list of dashboards', () => {
    const message = 'failed';
    const error = new Error(message);

    beforeEach(() => {
      mockAnalyticsDashboardsHandler = jest.fn().mockRejectedValue(error);

      createWrapper();

      return waitForPromises();
    });

    it('creates an alert for the error', () => {
      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        message,
        error,
      });
    });
  });
});

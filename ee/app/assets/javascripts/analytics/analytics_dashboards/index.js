import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import {
  convertObjectPropsToCamelCase,
  convertArrayToCamelCase,
  parseBoolean,
} from '~/lib/utils/common_utils';
import { injectVueAppBreadcrumbs } from '~/lib/utils/breadcrumbs';
import DashboardsApp from './dashboards_app.vue';
import createRouter from './router';
import AnalyticsDashboardsBreadcrumbs from './components/analytics_dashboards_breadcrumbs.vue';

const buildAnalyticsDashboardPointer = (analyticsDashboardPointerJSON = '') => {
  return analyticsDashboardPointerJSON.length
    ? convertObjectPropsToCamelCase(JSON.parse(analyticsDashboardPointerJSON))
    : null;
};

export default () => {
  const el = document.getElementById('js-analytics-dashboards-list-app');

  if (!el) {
    return false;
  }

  const {
    dashboardProject: analyticsDashboardPointerJSON = '',
    canConfigureDashboardsProject,
    trackingKey,
    namespaceId,
    namespaceName,
    namespaceFullPath,
    isProject,
    isGroup,
    collectorHost,
    chartEmptyStateIllustrationPath,
    dashboardEmptyStateIllustrationPath,
    analyticsSettingsPath,
    routerBase,
    features,
    availableVisualizations = '',
    rootNamespaceName,
    rootNamespaceFullPath,
  } = el.dataset;

  const analyticsDashboardPointer = buildAnalyticsDashboardPointer(analyticsDashboardPointerJSON);

  // We need the raw visualization information to augment the YAML configured dashboards
  // with the change in https://gitlab.com/gitlab-org/gitlab/-/issues/423427, we will be removing
  // the DORAChart from the graphql API, so until that is re-instated we should simply
  // hydrate this app with the visualization configuration from the backend.
  // Currently only include DORAChart, but will also include DORAPerformersScore (when its ready)
  // TODO: Remove the `availableVisualizations` property once we resolve https://gitlab.com/gitlab-org/gitlab/-/issues/414494
  //       and are able to return the VSD visualizations from the graphql endpoint
  const vsdAvailableVisualizations = availableVisualizations
    ? JSON.parse(availableVisualizations)
    : [];

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(
      {},
      {
        cacheConfig: {
          typePolicies: {
            Project: {
              fields: {
                customizableDashboards: {
                  keyArgs: ['projectPath', 'slug'],
                },
              },
            },
            CustomizableDashboards: {
              keyFields: ['slug'],
            },
          },
        },
      },
    ),
  });

  // This is a mini state to help the breadcrumb have the correct name
  const breadcrumbState = Vue.observable({
    name: '',
    updateName(value) {
      this.name = value;
    },
  });

  const router = createRouter(routerBase, breadcrumbState);

  injectVueAppBreadcrumbs(router, AnalyticsDashboardsBreadcrumbs);

  return new Vue({
    el,
    name: 'AnalyticsDashboardsRoot',
    apolloProvider,
    router,
    provide: {
      breadcrumbState,
      customDashboardsProject: analyticsDashboardPointer,
      canConfigureDashboardsProject: parseBoolean(canConfigureDashboardsProject),
      trackingKey,
      namespaceFullPath,
      namespaceId,
      isProject: parseBoolean(isProject),
      isGroup: parseBoolean(isGroup),
      namespaceName,
      collectorHost,
      chartEmptyStateIllustrationPath,
      dashboardEmptyStateIllustrationPath,
      analyticsSettingsPath,
      features: convertArrayToCamelCase(JSON.parse(features)),
      vsdAvailableVisualizations,
      rootNamespaceName,
      rootNamespaceFullPath,
    },
    render(h) {
      return h(DashboardsApp);
    },
  });
};

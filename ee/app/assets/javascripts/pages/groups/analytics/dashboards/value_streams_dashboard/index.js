import { createAlert } from '~/alert';
import { __ } from '~/locale';

try {
  (async () => {
    const { default: initApp } = gon.features.groupAnalyticsDashboardDynamicVsd
      ? await import('ee/analytics/analytics_dashboards')
      : await import('ee/analytics/dashboards/value_streams_dashboard');
    return initApp();
  })();
} catch (error) {
  createAlert({
    message: __('An error occurred. Please try again.'),
    captureError: true,
    error,
  });
}

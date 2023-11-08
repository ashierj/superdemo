(async () => {
  const { default: initApp } = gon.features.groupAnalyticsDashboards
    ? await import('ee/analytics/analytics_dashboards')
    : await import('ee/analytics/dashboards/value_streams_dashboard');
  return initApp();
})();

<script>
import CEWidgetApp from '~/vue_merge_request_widget/components/widget/app.vue';

export default {
  components: {
    MrMetricsWidget: () => import('ee/vue_merge_request_widget/extensions/metrics/index.vue'),
    MrSecurityWidgetEE: () =>
      import(
        'ee/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue'
      ),
    MrSecurityWidgetCE: () =>
      import(
        '~/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue'
      ),
    MrStatusChecksWidget: () =>
      import('ee/vue_merge_request_widget/extensions/status_checks/index.vue'),
    MrLicenseComplianceWidget: () =>
      import('ee/vue_merge_request_widget/extensions/license_compliance/index.vue'),
  },

  extends: CEWidgetApp,

  computed: {
    licenseComplianceWidget() {
      return this.mr?.enabledReports?.licenseScanning ? 'MrLicenseComplianceWidget' : undefined;
    },

    metricsWidget() {
      return this.mr.metricsReportsPath ? 'MrMetricsWidget' : undefined;
    },

    statusChecksWidget() {
      return this.mr.apiStatusChecksPath && !this.mr.isNothingToMergeState
        ? 'MrStatusChecksWidget'
        : undefined;
    },

    securityReportsWidget() {
      return this.mr.canReadVulnerabilities ? 'MrSecurityWidgetEE' : 'MrSecurityWidgetCE';
    },

    widgets() {
      return [
        this.licenseComplianceWidget,
        this.codeQualityWidget,
        this.testReportWidget,
        this.metricsWidget,
        this.statusChecksWidget,
        this.terraformPlansWidget,
        this.securityReportsWidget,
        this.accessibilityWidget,
      ].filter((w) => w);
    },
  },

  render: CEWidgetApp.render,
};
</script>

import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { parseBoolean } from '~/lib/utils/common_utils';

import createDefaultClient from '~/lib/graphql';

import { createRouter } from 'ee/compliance_dashboard/router';

export default () => {
  const el = document.getElementById('js-compliance-report');

  const {
    basePath,
    canAddEdit,
    mergeCommitsCsvExportPath,
    violationsCsvExportPath,
    frameworksCsvExportPath,
    groupPath,
    rootAncestorPath,
    pipelineConfigurationFullPathEnabled,
    pipelineConfigurationEnabled,
    complianceFrameworkReportUiEnabled,
  } = el.dataset;

  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const router = createRouter(basePath, {
    mergeCommitsCsvExportPath,
    groupPath,
    rootAncestorPath,
    complianceFrameworkReportUiEnabled: parseBoolean(complianceFrameworkReportUiEnabled),
  });

  return new Vue({
    el,
    apolloProvider,
    name: 'ComplianceReportsApp',
    router,
    provide: {
      groupPath,
      canAddEdit,
      pipelineConfigurationFullPathEnabled: parseBoolean(pipelineConfigurationFullPathEnabled),
      pipelineConfigurationEnabled: parseBoolean(pipelineConfigurationEnabled),
      complianceFrameworkReportUiEnabled: parseBoolean(complianceFrameworkReportUiEnabled),

      mergeCommitsCsvExportPath,
      violationsCsvExportPath,
      frameworksCsvExportPath,
    },
    render: (createElement) => createElement('router-view'),
  });
};

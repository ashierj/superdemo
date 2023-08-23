import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { createMockSubscription as createMockApolloSubscription } from 'mock-apollo-client';

import approvedByCurrentUser from 'test_fixtures/graphql/merge_requests/approvals/approvals.query.graphql.json';
import getStateQueryResponse from 'test_fixtures/graphql/merge_requests/get_state.query.graphql.json';
import readyToMergeResponse from 'test_fixtures/graphql/merge_requests/states/ready_to_merge.query.graphql.json';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';

import {
  registerExtension,
  registeredExtensions,
} from '~/vue_merge_request_widget/components/extensions';

// Force Jest to transpile and cache
// eslint-disable-next-line no-unused-vars
import _GroupedLoadPerformanceReportsApp from 'ee/ci/reports/load_performance_report/grouped_load_performance_reports_app.vue';

import MrWidgetOptions from 'ee/vue_merge_request_widget/mr_widget_options.vue';
import WidgetContainer from 'ee/vue_merge_request_widget/components/widget/app.vue';
import Approvals from '~/vue_merge_request_widget/components/approvals/approvals.vue';

// EE Widget Extensions
import licenseComplianceExtension from 'ee/vue_merge_request_widget/extensions/license_compliance';

import createMockApollo from 'helpers/mock_apollo_helper';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';

import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { SUCCESS } from '~/vue_merge_request_widget/components/deployment/constants';

// Force Jest to transpile and cache
// eslint-disable-next-line no-unused-vars
import _Deployment from '~/vue_merge_request_widget/components/deployment/deployment.vue';

import getStateQuery from '~/vue_merge_request_widget/queries/get_state.query.graphql';
import getStateSubscription from '~/vue_merge_request_widget/queries/get_state.subscription.graphql';
import readyToMergeSubscription from '~/vue_merge_request_widget/queries/states/ready_to_merge.subscription.graphql';
import readyToMergeQuery from 'ee_else_ce/vue_merge_request_widget/queries/states/ready_to_merge.query.graphql';
import mergeQuery from '~/vue_merge_request_widget/queries/states/new_ready_to_merge.query.graphql';
import approvalsQuery from 'ee_else_ce/vue_merge_request_widget/components/approvals/queries/approvals.query.graphql';
import approvedBySubscription from 'ee_else_ce/vue_merge_request_widget/components/approvals/queries/approvals.subscription.graphql';

import mockData from './mock_data';

jest.mock('~/vue_shared/components/help_popover.vue');

Vue.use(VueApollo);

describe('ee merge request widget options', () => {
  const allSubscriptions = {};
  let wrapper;
  let mock;

  const findWidgetContainer = () => wrapper.findComponent(WidgetContainer);
  const findApprovalsWidget = () => wrapper.findComponent(Approvals);
  const findPipelineContainer = () => wrapper.findByTestId('pipeline-container');
  const findMergedPipelineContainer = () => wrapper.findByTestId('merged-pipeline-container');

  const createComponent = ({ mountFn = shallowMountExtended, propsData = {} }) => {
    const queryHandlers = [
      [approvalsQuery, jest.fn().mockResolvedValue(approvedByCurrentUser)],
      [getStateQuery, jest.fn().mockResolvedValue(getStateQueryResponse)],
      [readyToMergeQuery, jest.fn().mockResolvedValue(readyToMergeResponse)],
      [
        mergeQuery,
        jest.fn().mockResolvedValue({
          data: {
            project: { id: 1, mergeRequest: { id: 1, userPermissions: { canMerge: true } } },
          },
        }),
      ],
    ];
    const subscriptionHandlers = [
      [
        approvedBySubscription,
        () => {
          // Please see https://github.com/Mike-Gibson/mock-apollo-client/blob/c85746f1433b42af83ef6ca0d2904ccad6076666/README.md#multiple-subscriptions
          // for why subscriptions must be mocked this way, in this context
          // Note that the keyed object -> array structure is so that:
          //  A) when necessary, we can publish (.next) events into the stream
          //  B) we can do that by name (per subscription) rather than as a single array of all subscriptions
          const sym = Symbol.for('approvedBySubscription');
          const newSub = createMockApolloSubscription();
          const container = allSubscriptions[sym] || [];

          container.push(newSub);
          allSubscriptions[sym] = container;

          return newSub;
        },
      ],
      [getStateSubscription, () => createMockApolloSubscription()],
      [readyToMergeSubscription, () => createMockApolloSubscription()],
    ];
    const apolloProvider = createMockApollo(queryHandlers);

    subscriptionHandlers.forEach(([query, stream]) => {
      apolloProvider.defaultClient.setRequestHandler(query, stream);
    });

    wrapper = mountFn(MrWidgetOptions, {
      propsData,
      apolloProvider,
      data() {
        return {
          loading: false,
        };
      },
    });
  };

  beforeEach(() => {
    gon.features = { asyncMrWidget: true };
    gl.mrWidgetData = { ...mockData };

    mock = new MockAdapter(axios);

    mock.onGet(mockData.merge_request_widget_path).reply(() => [HTTP_STATUS_OK, gl.mrWidgetData]);
    mock
      .onGet(mockData.merge_request_cached_widget_path)
      .reply(() => [HTTP_STATUS_OK, gl.mrWidgetData]);
  });

  afterEach(() => {
    registeredExtensions.extensions = [];

    // This is needed because the `fetchInitialData` is triggered while
    // the `mock.restore` is trying to clean up, causing a bunch of
    // unmocked requests...
    // This is not ideal and will be cleaned up in
    // https://gitlab.com/gitlab-org/gitlab/-/issues/214032
    return waitForPromises().then(() => {
      wrapper.destroy();
      wrapper = null;
      mock.restore();
    });
  });

  describe('computed', () => {
    describe('shouldRenderApprovals', () => {
      it('should return false when in empty state', async () => {
        createComponent({
          propsData: {
            mrData: {
              ...mockData,
              has_approvals_available: true,
            },
          },
        });
        Vue.set(wrapper.vm.mr, 'state', 'nothingToMerge');
        await nextTick();
        expect(findApprovalsWidget().exists()).toBe(false);
      });

      it('should return true when requiring approvals and in non-empty state', async () => {
        createComponent({
          mountFn: mountExtended,
          propsData: {
            mrData: {
              ...mockData,
              has_approvals_available: true,
            },
          },
        });
        Vue.set(wrapper.vm.mr, 'state', 'readyToMerge');
        await nextTick();
        expect(findApprovalsWidget().exists()).toBe(true);
      });
    });
  });

  describe('rendering deployments', () => {
    const deploymentMockData = {
      id: 15,
      name: 'review/diplo',
      url: '/root/acets-review-apps/environments/15',
      stop_url: '/root/acets-review-apps/environments/15/stop',
      metrics_url: '/root/acets-review-apps/environments/15/deployments/1/metrics',
      metrics_monitoring_url: '/root/acets-review-apps/environments/15/metrics',
      external_url: 'http://diplo.',
      external_url_formatted: 'diplo.',
      deployed_at: '2017-03-22T22:44:42.258Z',
      deployed_at_formatted: 'Mar 22, 2017 10:44pm',
      status: SUCCESS,
    };

    const deploymentsMockData = [
      deploymentMockData,
      {
        ...deploymentMockData,
        id: deploymentMockData.id + 1,
      },
    ];

    it('renders multiple deployments container', async () => {
      createComponent({
        propsData: {
          mrData: {
            ...mockData,
            deployments: deploymentsMockData,
          },
        },
      });
      await nextTick();
      expect(findPipelineContainer().exists()).toBe(true);
      expect(findPipelineContainer().props('mr').deployments).toEqual(deploymentsMockData);
      expect(findPipelineContainer().props('mr').postMergeDeployments).toHaveLength(0);
    });

    it('renders multiple deployments', async () => {
      createComponent({
        mountFn: mountExtended,
        propsData: {
          mrData: {
            ...mockData,
            deployments: deploymentsMockData,
          },
        },
      });
      await nextTick();
      expect(wrapper.findAll('.deploy-heading')).toHaveLength(2);
    });
  });

  describe('widget container', () => {
    it('renders the widget container', () => {
      createComponent({ propsData: { mrData: mockData } });
      expect(findWidgetContainer().exists()).toBe(true);
    });
  });

  describe('CI widget', () => {
    const sourceBranchLink = '<a href="/to/the/past">Link</a>';

    it('renders the pipeline widget', () => {
      createComponent({
        propsData: {
          mrData: {
            ...mockData,
            source_branch_with_namespace_link: sourceBranchLink,
          },
        },
      });

      expect(findMergedPipelineContainer().exists()).toBe(false);
      expect(findPipelineContainer().exists()).toBe(true);
      expect(findPipelineContainer().props('mr').sourceBranch).toBe(mockData.source_branch);
      expect(findPipelineContainer().props('mr').sourceBranchLink).toBe(sourceBranchLink);
    });

    it('renders the branch in the pipeline widget', () => {
      createComponent({
        mountFn: mountExtended,
        propsData: {
          mrData: {
            ...mockData,
            source_branch_with_namespace_link: sourceBranchLink,
          },
        },
      });

      const ciWidget = wrapper.find('.mr-state-widget .label-branch');
      expect(ciWidget.html()).toContain(sourceBranchLink);
    });
  });

  describe('data', () => {
    it('passes approval api paths to service', () => {
      const paths = {
        api_approvals_path: `${TEST_HOST}/api/approvals/path`,
        api_approval_settings_path: `${TEST_HOST}/api/approval/settings/path`,
        api_approve_path: `${TEST_HOST}/api/approve/path`,
        api_unapprove_path: `${TEST_HOST}/api/unapprove/path`,
      };

      createComponent({
        propsData: {
          mrData: {
            ...mockData,
            ...paths,
          },
        },
      });

      expect(wrapper.vm.service).toMatchObject(convertObjectPropsToCamelCase(paths));
    });
  });

  describe('license scanning report', () => {
    const licenseComparisonPath =
      '/group-name/project-name/-/merge_requests/78/license_scanning_reports';
    const licenseComparisonPathCollapsed =
      '/group-name/project-name/-/merge_requests/78/license_scanning_reports_collapsed';
    const fullReportPath = '/group-name/project-name/-/merge_requests/78/full_report';
    const settingsPath = '/group-name/project-name/-/licenses#licenses';
    const apiApprovalsPath = '/group-name/project-name/-/licenses#policies';

    const mrData = {
      ...mockData,
      license_scanning_comparison_path: licenseComparisonPath,
      license_scanning_comparison_collapsed_path: licenseComparisonPathCollapsed,
      api_approvals_path: apiApprovalsPath,
      license_scanning: {
        settings_path: settingsPath,
        full_report_path: fullReportPath,
      },
    };

    it('should render the license widget when the extension is registered', () => {
      gl.mrWidgetData = mrData;
      registerExtension(licenseComplianceExtension);
      createComponent({
        mountFn: mountExtended,
        propsData: { mrData },
      });

      expect(wrapper.findComponent({ name: 'WidgetLicenseCompliance' }).exists()).toBe(true);
    });

    it('should not render the license widget when the extension is not registered', () => {
      createComponent({
        mountFn: mountExtended,
        propsData: { mrData },
      });

      expect(wrapper.findComponent({ name: 'WidgetLicenseCompliance' }).exists()).toBe(false);
    });
  });
});

import { GlTableLite } from '@gitlab/ui';
import fixture from 'test_fixtures/pipelines/pipelines.json';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import LegacyPipelineMiniGraph from '~/ci/pipeline_mini_graph/legacy_pipeline_mini_graph.vue';
import PipelineFailedJobsWidget from '~/ci/pipelines_page/components/failure_widget/pipeline_failed_jobs_widget.vue';
import PipelineOperations from '~/ci/pipelines_page/components/pipeline_operations.vue';
import PipelineTriggerer from '~/ci/pipelines_page/components/pipeline_triggerer.vue';
import PipelineUrl from '~/ci/pipelines_page/components/pipeline_url.vue';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import PipelinesTimeago from '~/ci/pipelines_page/components/time_ago.vue';
import {
  PIPELINE_ID_KEY,
  BUTTON_TOOLTIP_RETRY,
  BUTTON_TOOLTIP_CANCEL,
  TRACKING_CATEGORIES,
} from '~/ci/constants';

import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';

describe('Pipelines Table', () => {
  let wrapper;
  let trackingSpy;

  const defaultProvide = {
    fullPath: '/my-project/',
    useFailedJobsWidget: false,
  };

  const provideWithFailedJobsWidget = {
    useFailedJobsWidget: true,
  };

  const { pipelines } = fixture;

  const defaultProps = {
    pipelines,
    pipelineIdType: PIPELINE_ID_KEY,
  };

  const [firstPipeline] = pipelines;

  const createComponent = ({ props = {}, provide = {}, stubs = {} } = {}) => {
    wrapper = mountExtended(PipelinesTable, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs: {
        PipelineOperations: true,
        ...stubs,
      },
    });
  };

  const findGlTableLite = () => wrapper.findComponent(GlTableLite);
  const findCiBadgeLink = () => wrapper.findComponent(CiBadgeLink);
  const findPipelineInfo = () => wrapper.findComponent(PipelineUrl);
  const findTriggerer = () => wrapper.findComponent(PipelineTriggerer);
  const findLegacyPipelineMiniGraph = () => wrapper.findComponent(LegacyPipelineMiniGraph);
  const findTimeAgo = () => wrapper.findComponent(PipelinesTimeago);
  const findActions = () => wrapper.findComponent(PipelineOperations);

  const findPipelineFailureWidget = () => wrapper.findComponent(PipelineFailedJobsWidget);
  const findTableRows = () => wrapper.findAllByTestId('pipeline-table-row');
  const findStatusTh = () => wrapper.findByTestId('status-th');
  const findPipelineTh = () => wrapper.findByTestId('pipeline-th');
  const findStagesTh = () => wrapper.findByTestId('stages-th');
  const findActionsTh = () => wrapper.findByTestId('actions-th');
  const findRetryBtn = () => wrapper.findByTestId('pipelines-retry-button');
  const findCancelBtn = () => wrapper.findByTestId('pipelines-cancel-button');

  describe('Pipelines Table', () => {
    beforeEach(() => {
      createComponent({ props: { viewType: 'root' } });
    });

    it('displays table', () => {
      expect(findGlTableLite().exists()).toBe(true);
    });

    it('should render table head with correct columns', () => {
      expect(findStatusTh().text()).toBe('Status');
      expect(findPipelineTh().text()).toBe('Pipeline');
      expect(findStagesTh().text()).toBe('Stages');
      expect(findActionsTh().text()).toBe('Actions');
    });

    it('should display a table row', () => {
      expect(findTableRows()).toHaveLength(pipelines.length);
    });

    describe('status cell', () => {
      it('should render a status badge', () => {
        expect(findCiBadgeLink().exists()).toBe(true);
      });
    });

    describe('pipeline cell', () => {
      it('should render pipeline information', () => {
        expect(findPipelineInfo().exists()).toBe(true);
      });

      it('should display the pipeline id', () => {
        expect(findPipelineInfo().text()).toContain(`#${firstPipeline.id}`);
      });
    });

    describe('stages cell', () => {
      it('should render pipeline mini graph', () => {
        expect(findLegacyPipelineMiniGraph().exists()).toBe(true);
      });

      it('should render the right number of stages', () => {
        const stagesLength = firstPipeline.details.stages.length;
        expect(findLegacyPipelineMiniGraph().props('stages')).toHaveLength(stagesLength);
      });

      it('should render the latest downstream pipelines only', () => {
        // component receives two downstream pipelines. one of them is already outdated
        // because we retried the trigger job, so the mini pipeline graph will only
        // render the newly created downstream pipeline instead
        expect(firstPipeline.triggered).toHaveLength(2);
        expect(findLegacyPipelineMiniGraph().props('downstreamPipelines')).toHaveLength(1);
      });

      describe('when pipeline does not have stages', () => {
        beforeEach(() => {
          createComponent({
            props: {
              pipelines: [
                {
                  ...firstPipeline,
                  details: {
                    ...firstPipeline.details,
                    stages: [],
                  },
                },
              ],
            },
          });
        });

        it('stages are not rendered', () => {
          expect(findLegacyPipelineMiniGraph().props('stages')).toHaveLength(0);
        });
      });
    });

    describe('duration cell', () => {
      it('should render duration information', () => {
        expect(findTimeAgo().exists()).toBe(true);
      });
    });

    describe('operations cell', () => {
      beforeEach(() => {
        createComponent({ stubs: { PipelineOperations } });
      });

      it('should render pipeline operations', () => {
        expect(findActions().exists()).toBe(true);
      });

      it('should render retry action tooltip', () => {
        expect(findRetryBtn().attributes('title')).toBe(BUTTON_TOOLTIP_RETRY);
      });

      it('should render cancel action tooltip', () => {
        expect(findCancelBtn().attributes('title')).toBe(BUTTON_TOOLTIP_CANCEL);
      });
    });

    describe('triggerer cell', () => {
      it('should render the pipeline triggerer', () => {
        expect(findTriggerer().exists()).toBe(true);
      });
    });

    describe('failed jobs details', () => {
      describe('when `useFailedJobsWidget` value is provided', () => {
        beforeEach(() => {
          createComponent({ provide: provideWithFailedJobsWidget });
        });

        it('renders', () => {
          // We have 2 rows per pipeline with the widget
          expect(findTableRows()).toHaveLength(pipelines.length * 2);
          expect(findPipelineFailureWidget().exists()).toBe(true);
        });

        it('passes the expected props', () => {
          expect(findPipelineFailureWidget().props()).toStrictEqual({
            failedJobsCount: firstPipeline.failed_builds.length,
            isPipelineActive: firstPipeline.active,
            pipelineIid: firstPipeline.iid,
            pipelinePath: firstPipeline.path,
            // Make sure the forward slash was removed
            projectPath: 'frontend-fixtures/pipelines-project',
          });
        });
      });

      describe('and `useFailedJobsWidget` value is not provided', () => {
        beforeEach(() => {
          createComponent();
        });

        it('does not render', () => {
          expect(findTableRows()).toHaveLength(pipelines.length);
          expect(findPipelineFailureWidget().exists()).toBe(false);
        });
      });
    });
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('when confirming to cancel a pipeline', () => {
      beforeEach(async () => {
        await findActions().vm.$emit('cancel-pipeline', firstPipeline);
      });

      it('emits the `cancel-pipeline` event', () => {
        expect(wrapper.emitted('cancel-pipeline')).toEqual([[firstPipeline]]);
      });
    });

    describe('when retrying a pipeline', () => {
      beforeEach(() => {
        findActions().vm.$emit('retry-pipeline', firstPipeline);
      });

      it('emits the `retry-pipeline` event', () => {
        expect(wrapper.emitted('retry-pipeline')).toEqual([[firstPipeline]]);
      });
    });

    describe('when refreshing pipelines', () => {
      beforeEach(() => {
        findActions().vm.$emit('refresh-pipelines-table');
      });

      it('emits the `refresh-pipelines-table` event', () => {
        expect(wrapper.emitted('refresh-pipelines-table')).toEqual([[]]);
      });
    });
  });

  describe('tracking', () => {
    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('tracks status badge click', () => {
      findCiBadgeLink().vm.$emit('ciStatusBadgeClick');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_ci_status_badge', {
        label: TRACKING_CATEGORIES.table,
      });
    });

    it('tracks pipeline mini graph stage click', () => {
      findLegacyPipelineMiniGraph().vm.$emit('miniGraphStageClick');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_minigraph', {
        label: TRACKING_CATEGORIES.table,
      });
    });
  });
});

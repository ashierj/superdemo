import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PipelineDetailsHeader from '~/ci/pipeline_details/header/pipeline_details_header.vue';
import getPipelineDetailsQuery from '~/ci/pipeline_details/header/graphql/queries/get_pipeline_header_data.query.graphql';
import {
  pipelineHeaderFinishedComputeMinutes,
  pipelineHeaderRunning,
  pipelineHeaderSuccess,
} from '../mock_data';

Vue.use(VueApollo);

describe('Pipeline details header', () => {
  let wrapper;

  const minutesHandler = jest.fn().mockResolvedValue(pipelineHeaderFinishedComputeMinutes);
  const successHandler = jest.fn().mockResolvedValue(pipelineHeaderSuccess);
  const runningHandler = jest.fn().mockResolvedValue(pipelineHeaderRunning);

  const findComputeMinutes = () => wrapper.findByTestId('compute-minutes');

  const defaultHandlers = [[getPipelineDetailsQuery, minutesHandler]];

  const defaultProvideOptions = {
    pipelineIid: 1,
    paths: {
      pipelinesPath: '/namespace/my-project/-/pipelines',
      fullProject: '/namespace/my-project',
    },
  };

  const defaultProps = {
    yamlErrors: 'errors',
    trigger: false,
  };

  const createMockApolloProvider = (handlers) => {
    return createMockApollo(handlers);
  };

  const createComponent = (handlers = defaultHandlers, props = defaultProps) => {
    wrapper = shallowMountExtended(PipelineDetailsHeader, {
      provide: {
        ...defaultProvideOptions,
      },
      propsData: {
        ...props,
      },
      apolloProvider: createMockApolloProvider(handlers),
    });
  };

  describe('finished pipeline', () => {
    it('displays compute minutes when not zero', async () => {
      createComponent();

      await waitForPromises();

      expect(findComputeMinutes().text()).toBe('25');
    });

    it('does not display compute minutes when zero', async () => {
      createComponent([[getPipelineDetailsQuery, successHandler]]);

      await waitForPromises();

      expect(findComputeMinutes().exists()).toBe(false);
    });
  });

  describe('running pipeline', () => {
    beforeEach(async () => {
      createComponent([[getPipelineDetailsQuery, runningHandler]]);

      await waitForPromises();
    });

    it('does not display compute minutes', () => {
      expect(findComputeMinutes().exists()).toBe(false);
    });
  });
});

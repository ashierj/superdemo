import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import {
  parseBoolean,
  historyReplaceState,
  buildUrlWithCurrentLocation,
} from '~/lib/utils/common_utils';
import { doesHashExistInUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import Translate from '~/vue_shared/translate';
import Pipelines from '~/ci/pipelines_page/pipelines.vue';
import PipelinesStore from './stores/pipelines_store';

Vue.use(Translate);
Vue.use(GlToast);
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initPipelinesIndex = (selector = '#pipelines-list-vue') => {
  const el = document.querySelector(selector);
  if (!el) {
    return null;
  }

  const {
    endpoint,
    artifactsEndpoint,
    artifactsEndpointPlaceholder,
    pipelineSchedulesPath,
    newPipelinePath,
    pipelineEditorPath,
    suggestedCiTemplates,
    canCreatePipeline,
    hasGitlabCi,
    ciLintPath,
    resetCachePath,
    projectId,
    defaultBranchName,
    params,
    iosRunnersAvailable,
    registrationToken,
    fullPath,
    visibilityPipelineIdType,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      artifactsEndpoint,
      artifactsEndpointPlaceholder,
      fullPath,
      iosRunnersAvailable: parseBoolean(iosRunnersAvailable),
      manualActionsLimit: 50,
      pipelineEditorPath,
      pipelineSchedulesPath,
      suggestedCiTemplates: JSON.parse(suggestedCiTemplates),
    },
    data() {
      return {
        store: new PipelinesStore(),
      };
    },
    created() {
      if (doesHashExistInUrl('delete_success')) {
        this.$toast.show(__('The pipeline has been deleted'));
        historyReplaceState(buildUrlWithCurrentLocation());
      }
    },
    render(createElement) {
      return createElement(Pipelines, {
        props: {
          canCreatePipeline: parseBoolean(canCreatePipeline),
          ciLintPath,
          defaultBranchName,
          defaultVisibilityPipelineIdType: visibilityPipelineIdType,
          endpoint,
          hasGitlabCi: parseBoolean(hasGitlabCi),
          newPipelinePath,
          params: JSON.parse(params),
          projectId,
          registrationToken,
          resetCachePath,
          store: this.store,
        },
      });
    },
  });
};

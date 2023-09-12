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
    pipelineScheduleUrl,
    emptyStateSvgPath,
    errorStateSvgPath,
    noPipelinesSvgPath,
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
      pipelineEditorPath,
      artifactsEndpoint,
      artifactsEndpointPlaceholder,
      suggestedCiTemplates: JSON.parse(suggestedCiTemplates),
      iosRunnersAvailable: parseBoolean(iosRunnersAvailable),
      fullPath,
      manualActionsLimit: 50,
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
          store: this.store,
          endpoint,
          pipelineScheduleUrl,
          emptyStateSvgPath,
          errorStateSvgPath,
          noPipelinesSvgPath,
          newPipelinePath,
          canCreatePipeline: parseBoolean(canCreatePipeline),
          hasGitlabCi: parseBoolean(hasGitlabCi),
          ciLintPath,
          resetCachePath,
          projectId,
          defaultBranchName,
          params: JSON.parse(params),
          registrationToken,
          defaultVisibilityPipelineIdType: visibilityPipelineIdType,
        },
      });
    },
  });
};

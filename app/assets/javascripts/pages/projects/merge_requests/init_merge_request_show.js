import Vue from 'vue';
import VueApollo from 'vue-apollo';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';
import { initPipelineCountListener } from '~/commit/pipelines/utils';
import { initIssuableSidebar } from '~/issuable';
import StatusBox from '~/issuable/components/status_box.vue';
import createDefaultClient from '~/lib/graphql';
import initSourcegraph from '~/sourcegraph';
import ZenMode from '~/zen_mode';
import initAwardsApp from '~/emoji/awards_app';
import MrWidgetHowToMergeModal from '~/vue_merge_request_widget/components/mr_widget_how_to_merge_modal.vue';
import getStateQuery from './queries/get_state.query.graphql';

export default function initMergeRequestShow() {
  new ZenMode(); // eslint-disable-line no-new
  initPipelineCountListener(document.querySelector('#commit-pipeline-table-view'));
  new ShortcutsIssuable(true); // eslint-disable-line no-new
  initSourcegraph();
  initIssuableSidebar();
  initAwardsApp(document.getElementById('js-vue-awards-block'));

  const el = document.querySelector('.js-mr-status-box');
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });
  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    provide: {
      query: getStateQuery,
      projectPath: el.dataset.projectPath,
      iid: el.dataset.iid,
    },
    render(h) {
      return h(StatusBox, {
        props: {
          initialState: el.dataset.state,
        },
      });
    },
  });

  const modalEl = document.getElementById('js-check-out-modal');

  // eslint-disable-next-line no-new
  new Vue({
    el: modalEl,
    render(h) {
      return h(MrWidgetHowToMergeModal, {
        props: {
          canMerge: modalEl.dataset.canMerge === 'true',
          isFork: modalEl.dataset.isFork === 'true',
          sourceBranch: modalEl.dataset.sourceBranch,
          sourceProjectPath: modalEl.dataset.sourceProjectPath,
          targetBranch: modalEl.dataset.targetBranch,
          sourceProjectDefaultUrl: modalEl.dataset.sourceProjectDefaultUrl,
          reviewingDocsPath: modalEl.dataset.reviewingDocsPath,
        },
      });
    },
  });
}

import '~/pages/projects/merge_requests/creations/new/index';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import UserCallout from '~/user_callout';
import SummaryCodeChanges from 'ee/merge_requests/components/summarize_code_changes.vue';
import createDefaultClient from '~/lib/graphql';
import initForm from '../../shared/init_form';

Vue.use(VueApollo);

initForm();
// eslint-disable-next-line no-new
new UserCallout();

const el = document.querySelector('.js-summarize-code-changes');

if (el) {
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const { projectId, sourceBranch, targetBranch } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    provide: {
      projectId,
      sourceBranch,
      targetBranch,
    },
    render(h) {
      return h(SummaryCodeChanges);
    },
  });
}

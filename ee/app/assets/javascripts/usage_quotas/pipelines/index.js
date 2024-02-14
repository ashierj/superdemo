import Vue from 'vue';
import VueApollo from 'vue-apollo';
import apolloProvider from 'ee/usage_quotas/shared/provider';
import { PIPELINES_TAB_METADATA_EL_SELECTOR } from '../constants';
import PipelineUsageApp from './components/app.vue';
import { parseProvideData } from './utils';

Vue.use(VueApollo);

export default () => {
  const el = document.querySelector(PIPELINES_TAB_METADATA_EL_SELECTOR);

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    name: 'PipelinesUsageView',
    provide: parseProvideData(el),
    apolloProvider,
    render(createElement) {
      return createElement(PipelineUsageApp);
    },
  });
};

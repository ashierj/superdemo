import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import CodeSuggestionsUsage from 'ee/usage_quotas/code_suggestions/components/code_suggestions_usage.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

function mountCodeSuggestionsUsageApp() {
  const el = document.getElementById('js-code-suggestions-page');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'CodeSuggestionsUsage',
    apolloProvider,
    provide: {
      isSaaS: false,
    },
    render: (h) => h(CodeSuggestionsUsage),
  });
}

mountCodeSuggestionsUsageApp();

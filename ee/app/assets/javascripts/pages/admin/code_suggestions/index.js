import Vue from 'vue';
import apolloProvider from 'ee/usage_quotas/shared/provider';
import CodeSuggestionsUsage from 'ee/usage_quotas/code_suggestions/components/code_suggestions_usage.vue';

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
      addDuoProHref: el.dataset.addDuoProSeatsUrl,
      subscriptionName: el.dataset.subscriptionName,
    },
    render: (h) => h(CodeSuggestionsUsage),
  });
}

mountCodeSuggestionsUsageApp();

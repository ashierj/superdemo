import Vue from 'vue';
import VueApollo from 'vue-apollo';
import CodeSuggestionsUsage from 'ee/usage_quotas/code_suggestions/components/code_suggestions_usage.vue';
import apolloProvider from 'ee/usage_quotas/shared/provider';

Vue.use(VueApollo);

export default (containerId = 'js-code-suggestions-usage-app') => {
  const el = document.getElementById(containerId);

  if (!el) {
    return false;
  }

  const {
    fullPath,
    groupId,
    firstName,
    lastName,
    companyName,
    namespaceId,
    buttonAttributes,
    createHandRaiseLeadPath,
    glmContent,
    productInteraction,
    trackAction,
    trackLabel,
    userName,
    addDuoProHref,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    name: 'CodeSuggestionsUsageApp',
    provide: {
      fullPath,
      groupId,
      createHandRaiseLeadPath,
      addDuoProHref,
      isSaaS: true,
      buttonAttributes: buttonAttributes && { ...JSON.parse(buttonAttributes), variant: 'confirm' },
      user: {
        namespaceId,
        userName,
        firstName,
        lastName,
        companyName,
        glmContent,
        productInteraction,
      },
      ctaTracking: {
        action: trackAction,
        label: trackLabel,
      },
    },
    render(createElement) {
      return createElement(CodeSuggestionsUsage);
    },
  });
};

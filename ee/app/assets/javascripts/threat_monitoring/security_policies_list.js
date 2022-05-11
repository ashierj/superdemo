import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import SecurityPoliciesApp from './components/policies/policies_app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (el, namespaceType) => {
  const {
    assignedPolicyProject,
    disableSecurityPolicyProject,
    emptyFilterSvgPath,
    emptyListSvgPath,
    documentationPath,
    groupPath,
    newPolicyPath,
    namespacePath,
  } = el.dataset;

  return new Vue({
    apolloProvider,
    el,
    name: 'PoliciesAppRoot',
    provide: {
      assignedPolicyProject: JSON.parse(assignedPolicyProject),
      disableSecurityPolicyProject: parseBoolean(disableSecurityPolicyProject),
      documentationPath,
      newPolicyPath,
      emptyFilterSvgPath,
      emptyListSvgPath,
      groupPath,
      namespacePath,
      namespaceType,
    },
    render(createElement) {
      return createElement(SecurityPoliciesApp);
    },
  });
};

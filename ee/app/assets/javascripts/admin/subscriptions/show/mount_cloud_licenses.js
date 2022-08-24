import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { helpPagePath } from '~/helpers/help_page_helper';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import CloudLicenseShowApp from './components/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.getElementById('js-show-subscription-page');

  if (!el) {
    return null;
  }

  const {
    buySubscriptionPath,
    congratulationSvgPath,
    customersPortalUrl,
    freeTrialPath,
    hasActiveLicense,
    licenseRemovePath,
    subscriptionActivationBannerCalloutName,
    subscriptionSyncPath,
    licenseUsageFilePath,
  } = el.dataset;
  const connectivityHelpURL = helpPagePath('/user/admin_area/license.html', {
    anchor: 'there-is-a-connectivity-issue',
  });

  return new Vue({
    el,
    name: 'CloudLicenseRoot',
    apolloProvider,
    provide: {
      buySubscriptionPath,
      congratulationSvgPath,
      connectivityHelpURL,
      customersPortalUrl,
      freeTrialPath,
      licenseRemovePath,
      subscriptionActivationBannerCalloutName,
      subscriptionSyncPath,
    },
    render: (h) =>
      h(CloudLicenseShowApp, {
        props: {
          hasActiveLicense: parseBoolean(hasActiveLicense),
          licenseUsageFilePath,
        },
      }),
  });
};

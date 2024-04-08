import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { getProductAnalyticsTabMetadata } from './tab_metadata';

Vue.use(VueApollo);

export default () => {
  const productAnalyticsTabMetadata = getProductAnalyticsTabMetadata({ includeEl: true });

  if (!productAnalyticsTabMetadata) return false;

  return new Vue(productAnalyticsTabMetadata.component);
};

import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import { getSeatTabMetadata } from './tab_metadata';

Vue.use(Vuex);
Vue.use(VueApollo);

export default () => {
  const seatTabMetadata = getSeatTabMetadata(true);

  if (!seatTabMetadata) return false;

  return new Vue(seatTabMetadata.component);
};

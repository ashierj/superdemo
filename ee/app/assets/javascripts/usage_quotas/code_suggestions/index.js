import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { getCodeSuggestionsTabMetadata } from './tab_metadata';

Vue.use(VueApollo);

export default () => {
  const codeSuggestionsTabMetadata = getCodeSuggestionsTabMetadata(true);

  if (!codeSuggestionsTabMetadata) return false;

  return new Vue(codeSuggestionsTabMetadata.component);
};

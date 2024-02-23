import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { getPipelineTabMetadata } from './tab_metadata';

Vue.use(VueApollo);

export default () => {
  const pipelineTabMetadata = getPipelineTabMetadata({ includeEl: true });

  if (!pipelineTabMetadata) return false;

  return new Vue(pipelineTabMetadata.component);
};

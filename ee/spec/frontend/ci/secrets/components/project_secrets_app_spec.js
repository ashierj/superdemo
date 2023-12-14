import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProjectSecretsApp from 'ee/ci/secrets/components/project_secrets_app.vue';

describe('ProjectSecretsApp', () => {
  let wrapper;

  Vue.use(VueRouter);
  Vue.use(VueApollo);

  const findRouterView = () => wrapper.findComponent({ ref: 'router-view' });

  const createComponent = (props = { projectPath: '/path/to/project', projectId: '123' }) => {
    wrapper = shallowMountExtended(ProjectSecretsApp, { propsData: { ...props } });
  };

  it('renders the project secrets app', () => {
    createComponent();

    expect(wrapper.findComponent(ProjectSecretsApp).exists()).toBe(true);
  });

  it('renders the router view', () => {
    createComponent();

    expect(findRouterView().exists()).toBe(true);
  });
});

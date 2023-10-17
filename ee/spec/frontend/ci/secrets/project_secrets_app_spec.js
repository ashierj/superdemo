import { shallowMount } from '@vue/test-utils';
import VueRouter from 'vue-router';
import Vue from 'vue';
import ProjectSecretsApp from 'ee/ci/secrets/project_secrets_app.vue';

describe('ProjectSecretsApp', () => {
  let wrapper;

  Vue.use(VueRouter);

  const findRouterView = () => wrapper.findComponent({ ref: 'router-view' });

  const createComponent = (props = { projectPath: '/path/to/project', projectId: '123' }) => {
    wrapper = shallowMount(ProjectSecretsApp, { propsData: { ...props } });
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

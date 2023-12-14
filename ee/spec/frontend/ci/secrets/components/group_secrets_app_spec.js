import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupSecretsApp from 'ee/ci/secrets/components/group_secrets_app.vue';

describe('GroupSecretsApp', () => {
  let wrapper;

  Vue.use(VueRouter);
  Vue.use(VueApollo);

  const findRouterView = () => wrapper.findComponent({ ref: 'router-view' });

  const createComponent = (props = { groupPath: '/path/to/group', groupId: '123' }) => {
    wrapper = shallowMountExtended(GroupSecretsApp, { propsData: { ...props } });
  };

  it('renders the group secrets app', () => {
    createComponent();

    expect(wrapper.findComponent(GroupSecretsApp).exists()).toBe(true);
  });

  it('renders the router view', () => {
    createComponent();

    expect(findRouterView().exists()).toBe(true);
  });
});

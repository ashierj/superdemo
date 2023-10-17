import { shallowMount } from '@vue/test-utils';
import VueRouter from 'vue-router';
import Vue from 'vue';
import { GlBreadcrumb } from '@gitlab/ui';
import SecretsBreadcrumbs from 'ee/ci/secrets/components/secrets_breadcrumbs.vue';
import createRouter from 'ee/ci/secrets/router';
import { s__ } from '~/locale';
import { INDEX_ROUTE_NAME, DETAILS_ROUTE_NAME } from 'ee/ci/secrets/constants';

describe('SecretsBreadcrumbs', () => {
  const rootBreadcrumb = {
    text: s__('Secrets|Secrets'),
    to: { name: INDEX_ROUTE_NAME },
  };
  const secretDetailsBreadcrumb = {
    text: 'project_secret_1',
    to: { name: DETAILS_ROUTE_NAME },
  };

  let wrapper;
  let router;

  Vue.use(VueRouter);

  const findBreadcrumbs = () => wrapper.findComponent(GlBreadcrumb);

  const createWrapper = () => {
    router = createRouter('/-/secrets');

    wrapper = shallowMount(SecretsBreadcrumbs, { router });
  };

  beforeEach(() => {
    createWrapper();
  });

  it('should render only the root breadcrumb when on root route', async () => {
    try {
      await router.push('/');
    } catch {
      // intentionally blank
      //
      // * in Vue.js 3 we need to refresh even '/' route
      // because we dynamically add routes and exception will not be raised
      //
      // * in Vue.js 2 this will trigger "redundant navigation" error and will be caught here
    }

    expect(findBreadcrumbs().props('items')).toStrictEqual([rootBreadcrumb]);
  });

  it.each`
    routeName             | route
    ${'New secret'}       | ${'/new'}
    ${'project_secret_1'} | ${'/project_secret_1/details'}
  `(
    'should render the root and $routeName breadcrumbs when on $route',
    async ({ routeName, route }) => {
      await router.push(route);

      expect(findBreadcrumbs().props('items')).toStrictEqual([
        rootBreadcrumb,
        expect.objectContaining({
          text: routeName,
        }),
      ]);
    },
  );

  it.each`
    routeName      | route
    ${'Audit log'} | ${'/project_secret_1/auditlog'}
    ${'Edit'}      | ${'/project_secret_1/edit'}
  `(
    'should render the root, secret details, and $routeName breadcrumbs when on $route',
    async ({ routeName, route }) => {
      await router.push(route);

      expect(findBreadcrumbs().props('items')).toStrictEqual([
        rootBreadcrumb,
        secretDetailsBreadcrumb,
        {
          text: routeName,
          to: undefined,
        },
      ]);
    },
  );
});

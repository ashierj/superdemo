import { GlTabs, GlTab } from '@gitlab/ui';
import { RouterLinkStub } from '@vue/test-utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { EDIT_ROUTE_NAME, DETAILS_ROUTE_NAME, AUDIT_LOG_ROUTE_NAME } from 'ee/ci/secrets/constants';
import SecretTabs from 'ee/ci/secrets/components/secret_tabs.vue';

describe('SecretTabs component', () => {
  let wrapper;

  const findEditSecretLink = () => wrapper.findByTestId('edit-secret-link');
  const findTabs = () => wrapper.findComponent(GlTabs);

  const $route = {
    params: {
      key: 'project_secret_1',
    },
  };

  const createComponent = (routeName) => {
    wrapper = shallowMountExtended(SecretTabs, {
      stubs: {
        GlTab,
        GlTabs,
        RouterLink: RouterLinkStub,
        RouterView: true,
      },
      mocks: {
        $route: { name: routeName, ...$route },
      },
    });
  };

  describe.each`
    description                  | routeName
    ${'details tab is active'}   | ${DETAILS_ROUTE_NAME}
    ${'audit log tab is active'} | ${AUDIT_LOG_ROUTE_NAME}
  `(`when $description`, ({ routeName }) => {
    it('shows tabs and a link to the edit secret page', () => {
      createComponent(routeName);

      expect(findTabs().exists()).toBe(true);
      expect(findEditSecretLink().props('to')).toStrictEqual({ name: EDIT_ROUTE_NAME });
    });
  });
});

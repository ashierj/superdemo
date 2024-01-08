import { GlBadge } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CustomPermissions from 'ee/members/components/table/custom_permissions.vue';
import enabledMemberRolePermissions from 'ee/members/graphql/queries/enabled_member_role_permissions.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_MEMBER_ROLE } from '~/graphql_shared/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

Vue.use(VueApollo);

jest.mock('~/sentry/sentry_browser_wrapper');

describe('CustomPermissions', () => {
  let wrapper;

  const customPermissions = [{ name: 'Read code' }, { name: 'Read vulnerability' }];
  const enabledMemberRoleResponse = jest.fn().mockResolvedValue({
    data: {
      memberRole: {
        id: 'gid://gitlab/MemberRole/400',
        enabledPermissions: {
          nodes: [
            {
              name: 'Admin merge request',
              value: 'ADMIN_MERGE_REQUEST',
            },
          ],
        },
      },
    },
  });

  const createComponent = ({ mockedResponse = enabledMemberRoleResponse } = {}) => {
    const apolloProvider = createMockApollo([[enabledMemberRolePermissions, mockedResponse]]);

    wrapper = shallowMountExtended(CustomPermissions, {
      apolloProvider,
      propsData: {
        memberRoleId: 10,
        customPermissions,
      },
    });
  };

  const findBadges = () => wrapper.findAllComponents(GlBadge);

  describe('when GraphQL queries success', () => {
    beforeEach(() => {
      createComponent();
      waitForPromises();
    });

    it('shows a title', () => {
      expect(wrapper.findByTestId('title').text()).toBe(wrapper.vm.$options.i18n.title);
    });

    it('shows badges', () => {
      const badges = findBadges();
      expect(badges).toHaveLength(2);

      expect(badges.at(0).props()).toMatchObject({ variant: 'success', size: 'sm' });
      expect(badges.at(0).text()).toBe('Read code');

      expect(badges.at(1).props()).toMatchObject({ variant: 'success', size: 'sm' });
      expect(badges.at(1).text()).toBe('Read vulnerability');
    });

    it('update badges', async () => {
      const memberRoleId = 400;
      wrapper.setProps({ memberRoleId });
      await waitForPromises();

      expect(enabledMemberRoleResponse).toHaveBeenCalledWith({
        id: convertToGraphQLId(TYPENAME_MEMBER_ROLE, memberRoleId),
      });
      expect(findBadges()).toHaveLength(1);
    });
  });

  describe('when GraphQL queries fail', () => {
    it('reports fetching errors to Sentry', async () => {
      const myError = new Error('dummy');
      createComponent({ mockedResponse: jest.fn().mockRejectedValue(myError) });

      const memberRoleId = 400;
      wrapper.setProps({ memberRoleId });
      await waitForPromises();

      expect(Sentry.captureException).toHaveBeenCalledWith(myError);
    });
  });
});

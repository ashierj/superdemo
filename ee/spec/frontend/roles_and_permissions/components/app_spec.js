import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';

import groupMemberRolesQuery from 'ee/invite_members/graphql/queries/group_member_roles.query.graphql';
import instanceMemberRolesQuery from 'ee/roles_and_permissions/graphql/instance_member_roles.query.graphql';

import CustomRolesApp from 'ee/roles_and_permissions/components/app.vue';
import CustomRolesEmptyState from 'ee/roles_and_permissions/components/custom_roles_empty_state.vue';
import CustomRolesTable from 'ee/roles_and_permissions/components/custom_roles_table.vue';

import { mockEmptyMemberRoles, mockMemberRoles, mockInstanceMemberRoles } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('CustomRolesApp', () => {
  let wrapper;

  const groupRolesSuccessQueryHandler = jest.fn().mockResolvedValue(mockMemberRoles);
  const instanceRolesSuccessQueryHandler = jest.fn().mockResolvedValue(mockInstanceMemberRoles);

  const createComponent = ({
    groupRolesQueryHandler = groupRolesSuccessQueryHandler,
    instanceRolesQueryHandler = instanceRolesSuccessQueryHandler,
    groupFullPath = 'test-group',
  } = {}) => {
    wrapper = shallowMountExtended(CustomRolesApp, {
      apolloProvider: createMockApollo([
        [groupMemberRolesQuery, groupRolesQueryHandler],
        [instanceMemberRolesQuery, instanceRolesQueryHandler],
      ]),
      provide: {
        groupFullPath,
        documentationPath: 'http://foo.bar',
      },
    });
  };

  const findEmptyState = () => wrapper.findComponent(CustomRolesEmptyState);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTable = () => wrapper.findComponent(CustomRolesTable);
  const findHeader = () => wrapper.find('header');
  const findCount = () => wrapper.findByTestId('custom-roles-count');
  const findButton = () => wrapper.findComponent(GlButton);

  describe('on creation', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when data has loaded', () => {
    describe('and there are no custom roles', () => {
      beforeEach(async () => {
        createComponent({
          groupRolesQueryHandler: jest.fn().mockResolvedValue(mockEmptyMemberRoles),
        });

        await waitForPromises();
      });

      it('renders the empty state', () => {
        expect(findEmptyState().exists()).toBe(true);
      });
    });

    describe('and there group-level custom roles', () => {
      beforeEach(async () => {
        createComponent();

        await waitForPromises();
      });

      it('fetches group-level member roles', () => {
        expect(groupRolesSuccessQueryHandler).toHaveBeenCalledWith({
          fullPath: 'test-group',
        });
      });

      it('renders the title', () => {
        expect(findHeader().text()).toContain('Custom roles');
      });

      it('renders the create new role button', () => {
        expect(findButton().exists()).toBe(true);
        expect(findButton().text()).toContain('Create new role');
      });

      it('renders the number of roles', () => {
        expect(findCount().text()).toBe('1 Custom role');
      });

      it('renders the table', () => {
        expect(findTable().exists()).toBe(true);

        expect(findTable().props('customRoles')).toEqual(
          mockMemberRoles.data.namespace.memberRoles.nodes,
        );
      });
    });

    describe('and there instance-level custom roles', () => {
      beforeEach(async () => {
        createComponent({
          groupFullPath: null,
        });

        await waitForPromises();
      });

      it('fetches instance-level member roles', () => {
        expect(instanceRolesSuccessQueryHandler).toHaveBeenCalledWith({});
      });

      it('renders the table', () => {
        expect(findTable().exists()).toBe(true);

        expect(findTable().props('customRoles')).toEqual(
          mockInstanceMemberRoles.data.memberRoles.nodes,
        );
      });
    });

    describe('and there is an error fetching the data', () => {
      beforeEach(async () => {
        createComponent({
          groupRolesQueryHandler: jest.fn().mockRejectedValue(new Error('GraphQL Error')),
        });

        await waitForPromises();
      });

      it('renders an error message', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Failed to fetch roles.',
        });
      });
    });
  });
});

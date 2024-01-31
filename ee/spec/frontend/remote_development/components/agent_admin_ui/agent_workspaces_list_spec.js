import { mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { GlAlert, GlButton, GlLink, GlSkeletonLoader } from '@gitlab/ui';
import { logError } from '~/lib/logger';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import AgentWorkspacesList from 'ee/remote_development/components/agent_admin_ui/agent_workspaces_list.vue';
import WorkspaceEmptyState from 'ee/remote_development/components/list/empty_state.vue';
import WorkspacesTable from 'ee/remote_development/components/list/workspaces_table.vue';
import WorkspacesListPagination from 'ee/remote_development/components/list/workspaces_list_pagination.vue';
import agentWorkspacesListQuery from 'ee/remote_development/graphql/queries/agent_workspaces_list.query.graphql';
import userWorkspacesProjectsNamesQuery from 'ee/remote_development/graphql/queries/user_workspaces_projects_names.query.graphql';
import { populateWorkspacesWithProjectNames } from 'ee/remote_development/services/utils';
import {
  AGENT_WORKSPACES_LIST_QUERY_RESULT,
  AGENT_WORKSPACES_LIST_QUERY_EMPTY_RESULT,
  WORKSPACES_PROJECT_NAMES_QUERY_RESULT,
} from '../../mock_data';

jest.mock('~/lib/logger');

Vue.use(VueApollo);

const SVG_PATH = '/assets/illustrations/empty_states/empty_workspaces.svg';
const AGENT_NAME = 'agent-name';
const PROJECT_PATH = 'project/path';

describe('remote_development/components/agent_admin_ui/agent_workspaces_list.vue', () => {
  let wrapper;
  let mockApollo;
  let agentWorkspacesListQueryHandler;
  let userWorkspacesProjectNamesQueryHandler;

  const buildMockApollo = () => {
    agentWorkspacesListQueryHandler = jest
      .fn()
      .mockResolvedValueOnce(AGENT_WORKSPACES_LIST_QUERY_RESULT);
    userWorkspacesProjectNamesQueryHandler = jest
      .fn()
      .mockResolvedValueOnce(WORKSPACES_PROJECT_NAMES_QUERY_RESULT);

    mockApollo = createMockApollo([
      [agentWorkspacesListQuery, agentWorkspacesListQueryHandler],
      [userWorkspacesProjectsNamesQuery, userWorkspacesProjectNamesQueryHandler],
    ]);
  };
  const createWrapper = () => {
    // noinspection JSCheckFunctionSignatures
    wrapper = mount(AgentWorkspacesList, {
      apolloProvider: mockApollo,
      provide: {
        emptyStateSvgPath: SVG_PATH,
      },
      props: {
        agentName: AGENT_NAME,
        projectPath: PROJECT_PATH,
      },
    });
  };
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findHelpLink = () => wrapper.findComponent(GlLink);
  const findTable = () => wrapper.findComponent(WorkspacesTable);
  const findPagination = () => wrapper.findComponent(WorkspacesListPagination);
  const findAllConfirmButtons = () =>
    wrapper.findAllComponents(GlButton).filter((button) => button.props().variant === 'confirm');

  beforeEach(() => {
    buildMockApollo();
  });

  describe('when no workspaces are available', () => {
    beforeEach(async () => {
      agentWorkspacesListQueryHandler.mockReset();
      agentWorkspacesListQueryHandler.mockResolvedValueOnce(
        AGENT_WORKSPACES_LIST_QUERY_EMPTY_RESULT,
      );

      createWrapper();
      await waitForPromises();
    });

    it('renders empty state when no workspaces are available', () => {
      expect(wrapper.findComponent(WorkspaceEmptyState).exists()).toBe(true);
    });

    it('renders only one confirm button when empty state is present', () => {
      expect(findAllConfirmButtons().length).toBe(1);
    });

    it('does not render the workspaces table', () => {
      expect(findTable().exists()).toBe(false);
    });

    it('does not render the workspaces pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  it('shows loading state when workspaces are being fetched', () => {
    createWrapper();
    expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
  });

  describe('default (with nodes)', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('renders table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('renders pagination', () => {
      expect(findPagination().exists()).toBe(true);
    });

    it('provides workspaces data to the workspaces table', () => {
      expect(findTable(wrapper).props('workspaces')).toEqual(
        populateWorkspacesWithProjectNames(
          AGENT_WORKSPACES_LIST_QUERY_RESULT.data.project.clusterAgent.workspaces.nodes,
          WORKSPACES_PROJECT_NAMES_QUERY_RESULT.data.projects.nodes,
        ),
      );
    });

    it('does not call log error', () => {
      expect(logError).not.toHaveBeenCalled();
    });

    it('does not show alert', () => {
      expect(findAlert(wrapper).exists()).toBe(false);
    });

    describe('when pagination component emits input event', () => {
      it('refetches workspaces starting at the specified cursor', async () => {
        const pageVariables = {
          after: 'end',
          first: 10,
          agentName: AGENT_NAME,
          projectPath: PROJECT_PATH,
        };

        createWrapper();

        await waitForPromises();

        expect(agentWorkspacesListQueryHandler).toHaveBeenCalledTimes(1);

        findPagination().vm.$emit('input', pageVariables);

        await waitForPromises();

        expect(agentWorkspacesListQueryHandler).toHaveBeenCalledTimes(2);
        expect(agentWorkspacesListQueryHandler).toHaveBeenLastCalledWith(pageVariables);
      });
    });
  });

  describe('when workspace table emits updateFailed event', () => {
    const error = 'Failed to stop workspace';

    beforeEach(async () => {
      createWrapper();
      await waitForPromises();

      findTable().vm.$emit('updateFailed', { error });
    });

    it('displays the error attached to the event', async () => {
      await nextTick();

      expect(findAlert().text()).toBe(error);
    });

    describe('when workspace table emits updateSucceed event', () => {
      it('dismisses the previous update error', async () => {
        expect(findAlert().text()).toBe(error);

        findTable().vm.$emit('updateSucceed');

        await nextTick();

        expect(findAlert().exists()).toBe(false);
      });
    });
  });

  describe.each`
    query                            | queryHandlerFactory
    ${'userWorkspaces'}              | ${() => agentWorkspacesListQueryHandler}
    ${'userWorkspacesProjectsNames'} | ${() => userWorkspacesProjectNamesQueryHandler}
  `('when $query query fails', ({ queryHandlerFactory }) => {
    const ERROR = new Error('Something bad!');

    beforeEach(async () => {
      const queryHandler = queryHandlerFactory();

      queryHandler.mockReset();
      queryHandler.mockRejectedValueOnce(ERROR);

      createWrapper();
      await waitForPromises();
    });

    it('does not render table', () => {
      expect(findTable().exists()).toBe(false);
    });

    it('logs error', () => {
      expect(logError).toHaveBeenCalledWith(ERROR);
    });

    it('shows alert', () => {
      expect(findAlert().text()).toBe(
        'Unable to load current workspaces. Please try again or contact an administrator.',
      );
    });

    it('hides error when alert is dismissed', async () => {
      findAlert().vm.$emit('dismiss');

      await nextTick();

      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('fixed elements', () => {
    beforeEach(async () => {
      createWrapper();

      await waitForPromises();
    });

    it('displays a link that navigates to the workspaces help page', () => {
      expect(findHelpLink().attributes().href).toContain('user/workspace/index.md');
    });
  });
});

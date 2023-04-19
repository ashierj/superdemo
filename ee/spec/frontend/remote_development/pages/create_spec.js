import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlFormSelect, GlForm } from '@gitlab/ui';
import SearchProjectsListbox from 'ee/remote_development/components/create/search_projects_listbox.vue';
import WorkspaceCreate, { i18n } from 'ee/remote_development/pages/create.vue';
import GetProjectDetailsQuery from 'ee/remote_development/components/create/get_project_details_query.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import createMockApollo from 'helpers/mock_apollo_helper';
import { DEFAULT_EDITOR } from 'ee/remote_development/constants';
import { visitUrl } from '~/lib/utils/url_utility';
import waitForPromises from 'helpers/wait_for_promises';
import { logError } from '~/lib/logger';
import { createAlert } from '~/alert';
import { GET_PROJECT_DETAILS_QUERY_RESULT, WORKSPACE_CREATE_MUTATION_RESULT } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility');
jest.mock('~/lib/logger');
jest.mock('~/alert');

describe('remote_development/pages/create.vue', () => {
  const selectedProjectFixture = {
    fullPath: 'gitlab-org/gitlab',
    nameWithNamespace: 'GitLab Org / GitLab',
  };
  const selectedClusterAgentIDFixture = 'agents/1';
  const clusterAgentsFixture = [{ text: 'Agent', value: 'agents/1' }];
  const GlFormSelectStub = stubComponent(GlFormSelect, {
    props: ['options'],
  });
  let wrapper;
  let workspaceCreateMutationHandler;
  let mockApollo;

  const buildMockApollo = () => {
    workspaceCreateMutationHandler = jest
      .fn()
      .mockResolvedValueOnce(WORKSPACE_CREATE_MUTATION_RESULT.data.workspaceCreate);
    mockApollo = createMockApollo([], {
      Mutation: {
        workspaceCreate: workspaceCreateMutationHandler,
      },
    });
  };

  const createWrapper = () => {
    wrapper = shallowMountExtended(WorkspaceCreate, {
      apolloProvider: mockApollo,
      stubs: {
        GlFormSelect: GlFormSelectStub,
      },
    });
  };

  const findSearchProjectsListbox = () => wrapper.findComponent(SearchProjectsListbox);
  const findNoAgentsGlAlert = () => wrapper.findByTestId('no-agents-alert');
  const findNoDevFileGlAlert = () => wrapper.findByTestId('no-dev-file-alert');
  const findClusterAgentsFormGroup = () =>
    wrapper.findByTestId('workspace-cluster-agent-form-group');
  const findGetProjectDetailsQuery = () => wrapper.findComponent(GetProjectDetailsQuery);
  const findCreateWorkspaceButton = () => wrapper.findByTestId('create-workspace');
  const findClusterAgentsFormSelect = () => wrapper.findComponent(GlFormSelectStub);
  const emitGetProjectDetailsQueryResult = ({
    clusterAgents = [],
    hasDevFile = false,
    groupPath = GET_PROJECT_DETAILS_QUERY_RESULT.data.project.group.fullPath,
    id = GET_PROJECT_DETAILS_QUERY_RESULT.data.project.id,
  }) =>
    findGetProjectDetailsQuery().vm.$emit('result', {
      clusterAgents,
      hasDevFile,
      groupPath,
      id,
    });
  const selectProject = (project = selectedProjectFixture) =>
    findSearchProjectsListbox().vm.$emit('input', project);
  const selectClusterAgent = () =>
    findClusterAgentsFormSelect().vm.$emit('input', selectedClusterAgentIDFixture);
  const submitCreateWorkspaceForm = () =>
    wrapper.findComponent(GlForm).vm.$emit('submit', { preventDefault: jest.fn() });

  beforeEach(() => {
    buildMockApollo();
  });

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('displays a cancel button that allows navigating to the workspaces list', () => {
      expect(wrapper.findByTestId('cancel-workspace').attributes().to).toBe('root');
    });

    it('disables create workspace button', () => {
      expect(findCreateWorkspaceButton().props().disabled).toBe(true);
    });
  });

  describe('when a project does not have cluster agents', () => {
    beforeEach(async () => {
      createWrapper();

      await selectProject();
      await emitGetProjectDetailsQueryResult({ clusterAgents: [] });
    });
    it('displays danger alert indicating it', () => {
      expect(findNoAgentsGlAlert().props()).toMatchObject({
        title: i18n.alerts.noAgents.title,
        variant: 'danger',
        dismissible: false,
      });
    });

    it('does not display cluster agents form select group', () => {
      expect(findClusterAgentsFormGroup().exists()).toBe(false);
    });

    describe('when a project does not have a .devfile file', () => {
      it('does not display a devfile alert', async () => {
        createWrapper();

        await selectProject();
        await emitGetProjectDetailsQueryResult({
          hasDevFile: false,
        });

        expect(findNoDevFileGlAlert().exists()).toBe(false);
      });
    });
  });

  describe('when a project has cluster agents', () => {
    beforeEach(async () => {
      createWrapper();

      await selectProject();
      await emitGetProjectDetailsQueryResult({ clusterAgents: clusterAgentsFixture });
    });

    it('does not display danger alert', () => {
      expect(findNoAgentsGlAlert().exists()).toBe(false);
    });

    it('displays cluster agents form select group', () => {
      expect(findClusterAgentsFormGroup().exists()).toBe(true);
    });

    it('populates cluster agents form select with cluster agents', () => {
      expect(findClusterAgentsFormSelect().props().options).toBe(clusterAgentsFixture);
    });

    describe('when a project have a .devfile file', () => {
      it('does not display a devfile alert', async () => {
        createWrapper();

        await selectProject();
        await emitGetProjectDetailsQueryResult({
          hasDevFile: true,
          clusterAgents: clusterAgentsFixture,
        });

        expect(findNoDevFileGlAlert().exists()).toBe(false);
      });
    });

    describe('when a project does not have a .devfile file', () => {
      it('displays a devfile alert', async () => {
        createWrapper();

        await selectProject();
        await emitGetProjectDetailsQueryResult({
          hasDevFile: false,
          clusterAgents: clusterAgentsFixture,
        });

        expect(findNoDevFileGlAlert().props()).toMatchObject({
          title: i18n.alerts.noDevFile.title,
          variant: 'info',
          dismissible: false,
        });
      });
    });
  });

  describe('when a project and a cluster agent are selected', () => {
    beforeEach(async () => {
      createWrapper();

      await selectProject();
      await emitGetProjectDetailsQueryResult({ clusterAgents: clusterAgentsFixture });
      await selectClusterAgent();
    });

    it('enables create workspace button', () => {
      expect(findCreateWorkspaceButton().props().disabled).toBe(false);
    });

    describe('when selecting a project again', () => {
      beforeEach(async () => {
        await selectProject({ nameWithNamespace: 'New Project', fullPath: 'new-project' });
      });

      it('cleans the selected cluster agent', () => {
        expect(findClusterAgentsFormGroup().exists()).toBe(false);
      });
    });

    describe('when clicking Create Workspace button', () => {
      it('submits workspaceCreate mutation', async () => {
        await submitCreateWorkspaceForm();

        expect(workspaceCreateMutationHandler).toHaveBeenCalledWith(
          expect.any(Object),
          {
            input: {
              clusterAgentId: selectedClusterAgentIDFixture,
              projectId: GET_PROJECT_DETAILS_QUERY_RESULT.data.project.id,
              groupPath: GET_PROJECT_DETAILS_QUERY_RESULT.data.project.group.fullPath,
              editor: DEFAULT_EDITOR,
            },
          },
          expect.any(Object),
          expect.any(Object),
        );
      });

      it('sets Create Workspace button as loading', async () => {
        await submitCreateWorkspaceForm();

        expect(findCreateWorkspaceButton().props().loading).toBe(true);
      });

      describe('when the workspaceCreate mutation succeeds', () => {
        it('redirects the user to the workspace editor', async () => {
          await submitCreateWorkspaceForm();
          await waitForPromises();

          expect(visitUrl).toHaveBeenCalledWith(
            WORKSPACE_CREATE_MUTATION_RESULT.data.workspaceCreate.workspace.url,
          );
        });
      });

      describe('when the workspaceCreate mutation fails', () => {
        beforeEach(async () => {
          workspaceCreateMutationHandler.mockReset();
          workspaceCreateMutationHandler.mockRejectedValueOnce(new Error());

          await submitCreateWorkspaceForm();
          await waitForPromises();
        });

        it('logs error', () => {
          expect(logError).toHaveBeenCalled();
        });

        it('sets Create Workspace button as not loading', () => {
          expect(findCreateWorkspaceButton().props().loading).toBe(false);
        });

        it('displays alert indicating that creating a workspace failed', () => {
          expect(createAlert).toHaveBeenCalledWith({ message: i18n.createWorkspaceFailedMessage });
        });
      });
    });
  });

  describe('when fetching project details fails', () => {
    beforeEach(() => {
      createWrapper();

      wrapper.findComponent(GetProjectDetailsQuery).vm.$emit('error');
    });

    it('displays alert indicating that fetching project details failed', () => {
      expect(createAlert).toHaveBeenCalledWith({ message: i18n.fetchProjectDetailsFailedMessage });
    });
  });
});

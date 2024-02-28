import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProjectsToggleList from 'ee/security_orchestration/components/policy_drawer/projects_toggle_list.vue';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import getGroupProjects from 'ee/security_orchestration/graphql/queries/get_group_projects.query.graphql';
import ToggleList from 'ee/security_orchestration/components/policy_drawer/toggle_list.vue';

describe('ProjectsToggleList', () => {
  let wrapper;
  let requestHandlers;

  const defaultNodes = [
    { id: convertToGraphQLId(TYPENAME_PROJECT, 1), name: '1', fullPath: 'project-1-full-path' },
    { id: convertToGraphQLId(TYPENAME_PROJECT, 2), name: '2', fullPath: 'project-2-full-path' },
  ];

  const defaultNodesIds = defaultNodes.map(({ id }) => id);

  const defaultPageInfo = {
    __typename: 'PageInfo',
    hasNextPage: false,
    hasPreviousPage: false,
    startCursor: null,
    endCursor: null,
  };

  const mockApolloHandlers = ({ nodes = defaultNodes, hasNextPage = false } = {}) => {
    return {
      getGroupProjects: jest.fn().mockResolvedValue({
        data: {
          id: 1,
          group: {
            id: 2,
            projects: {
              nodes,
              pageInfo: { ...defaultPageInfo, hasNextPage },
            },
          },
        },
      }),
    };
  };

  const createMockApolloProvider = (handlers) => {
    Vue.use(VueApollo);

    requestHandlers = handlers;
    return createMockApollo([[getGroupProjects, requestHandlers.getGroupProjects]]);
  };

  const createComponent = ({
    propsData = {},
    provide = {},
    handlers = mockApolloHandlers(),
  } = {}) => {
    wrapper = shallowMountExtended(ProjectsToggleList, {
      apolloProvider: createMockApolloProvider(handlers),
      provide: {
        namespaceType: NAMESPACE_TYPES.GROUP,
        namespacePath: 'gitlab-org',
        rootNamespacePath: 'gitlab-org-root',
        ...provide,
      },
      propsData: {
        projectIds: [],
        ...propsData,
      },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findToggleList = () => wrapper.findComponent(ToggleList);
  const findHeader = () => wrapper.findByTestId('toggle-list-header');

  describe('all projects', () => {
    describe('many projects', () => {
      beforeEach(() => {
        createComponent();
      });

      it('should render loading icon', () => {
        expect(findLoadingIcon().exists()).toBe(true);
        expect(findToggleList().exists()).toBe(false);
      });

      it('should render toggle list with full project list', async () => {
        await waitForPromises();
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findToggleList().exists()).toBe(true);
        expect(findToggleList().props('items')).toHaveLength(2);
      });

      it('should render header for all projects', async () => {
        await waitForPromises();

        expect(findHeader().text()).toBe('All 2 projects in this group');
      });
    });

    describe('single project', () => {
      it('should render header for all projects when there is single project', async () => {
        createComponent({
          handlers: mockApolloHandlers({ nodes: [defaultNodes[0]] }),
        });

        await waitForPromises();

        expect(findHeader().text()).toBe('1 project in this group');
      });
    });
  });

  describe('specific projects', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          projectIds: [1],
          including: true,
        },
      });
    });

    it('should render toggle list with specific projects', async () => {
      await waitForPromises();
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findToggleList().exists()).toBe(true);

      expect(requestHandlers.getGroupProjects).toHaveBeenCalledWith({
        fullPath: 'gitlab-org',
        projectIds: [defaultNodesIds[0]],
      });
    });
    it('should render header for specific projects', async () => {
      await waitForPromises();

      expect(findHeader().text()).toBe('2 projects:');
    });
  });

  describe('all projects except specific projects', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          projectIds: [2],
          including: false,
        },
      });
    });

    it('should render toggle list with excluded projects', async () => {
      await waitForPromises();
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findToggleList().exists()).toBe(true);

      expect(requestHandlers.getGroupProjects).toHaveBeenCalledWith({
        fullPath: 'gitlab-org',
        projectIds: [defaultNodesIds[1]],
      });
    });

    it('should render header for excluded projects', async () => {
      await waitForPromises();

      expect(findHeader().text()).toBe('All projects in this group except:');
    });
  });

  describe('failed query', () => {
    it('should emit error when query fails', async () => {
      createComponent({
        handlers: {
          getGroupProjects: jest.fn().mockRejectedValue({}),
        },
      });

      await waitForPromises();
      expect(wrapper.emitted('projects-query-error')).toHaveLength(1);
    });
  });

  describe('paginated toggle list', () => {
    beforeEach(async () => {
      createComponent({
        handlers: mockApolloHandlers({ hasNextPage: true }),
      });

      await waitForPromises();
    });

    it('should load more projects', async () => {
      expect(findToggleList().props('hasNextPage')).toBe(true);
      expect(findToggleList().props('page')).toBe(1);
      expect(findToggleList().props('items')).toHaveLength(2);

      findToggleList().vm.$emit('load-next-page');
      await waitForPromises();

      expect(findToggleList().props('page')).toBe(2);
      expect(findToggleList().props('items')).toHaveLength(4);

      findToggleList().vm.$emit('load-next-page');
      await waitForPromises();

      expect(findToggleList().props('page')).toBe(3);
      expect(findToggleList().props('items')).toHaveLength(6);
    });
  });

  describe('project level', () => {
    it('should render toggle list with specific projects on project level', async () => {
      createComponent({
        provide: {
          namespaceType: NAMESPACE_TYPES.PROJECT,
        },
      });

      await waitForPromises();
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findToggleList().exists()).toBe(true);

      expect(requestHandlers.getGroupProjects).toHaveBeenCalledWith({
        fullPath: 'gitlab-org-root',
        projectIds: [],
      });
    });
  });

  describe('partial list', () => {
    it('renders partial lists for projects', async () => {
      createComponent({
        propsData: {
          projectsToShow: 3,
          inlineList: true,
        },
      });

      await waitForPromises();

      expect(findToggleList().props('itemsToShow')).toBe(3);
      expect(findToggleList().props('inlineList')).toBe(true);
    });
  });
});

import { GlAlert, GlButton } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { cloneDeep } from 'lodash';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { captureException } from '~/ci/runner/sentry_utils';
import NamespaceStorageApp from 'ee/usage_quotas/storage/components/namespace_storage_app.vue';
import ProjectList from 'ee/usage_quotas/storage/components/project_list.vue';
import getNamespaceStorageQuery from 'ee/usage_quotas/storage/queries/namespace_storage.query.graphql';
import getProjectListStorageQuery from 'ee/usage_quotas/storage/queries/project_list_storage.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import SearchAndSortBar from 'ee/usage_quotas/components/search_and_sort_bar/search_and_sort_bar.vue';
import StorageUsageStatistics from 'ee/usage_quotas/storage/components/storage_usage_statistics.vue';
import {
  mockGetNamespaceStorageGraphQLResponse,
  mockGetProjectListStorageGraphQLResponse,
} from 'jest/usage_quotas/storage/mock_data';
import { defaultNamespaceProvideValues } from '../mock_data';

jest.mock('~/ci/runner/sentry_utils');

Vue.use(VueApollo);

describe('NamespaceStorageApp', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const getNamespaceStorageHandler = jest.fn();
  const getProjectListStorageHandler = jest.fn();

  const findStorageUsageStatistics = () => wrapper.findComponent(StorageUsageStatistics);
  const findSearchAndSortBar = () => wrapper.findComponent(SearchAndSortBar);
  const findProjectList = () => wrapper.findComponent(ProjectList);
  const findPrevButton = () => wrapper.findByTestId('prevButton');
  const findNextButton = () => wrapper.findByTestId('nextButton');
  const findAlert = () => wrapper.findComponent(GlAlert);

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = mountExtended(NamespaceStorageApp, {
      apolloProvider: createMockApollo([
        [getNamespaceStorageQuery, getNamespaceStorageHandler],
        [getProjectListStorageQuery, getProjectListStorageHandler],
      ]),
      provide: {
        ...defaultNamespaceProvideValues,
        ...provide,
      },
    });
  };

  beforeEach(() => {
    getNamespaceStorageHandler.mockResolvedValue(mockGetNamespaceStorageGraphQLResponse);
    getProjectListStorageHandler.mockResolvedValue(mockGetProjectListStorageGraphQLResponse);
  });

  describe('Namespace usage overview', () => {
    beforeEach(async () => {
      createComponent({
        provide: {
          purchaseStorageUrl: 'some-fancy-url',
        },
      });
      await waitForPromises();
    });

    it('renders purchase more storage button', () => {
      const purchaseButton = wrapper.findComponent(GlButton);

      expect(purchaseButton.exists()).toBe(true);
    });
  });

  describe('project list', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders the 2 projects', () => {
      expect(findProjectList().props('projects')).toHaveLength(2);
    });
  });

  describe('sorting projects', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets default sorting', () => {
      expect(getProjectListStorageHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          sortKey: 'STORAGE_SIZE_DESC',
        }),
      );
      const projectList = findProjectList();
      expect(projectList.props('sortBy')).toBe('storage');
      expect(projectList.props('sortDesc')).toBe(true);
    });

    it('forms a sorting order string for STORAGE sorting', async () => {
      findProjectList().vm.$emit('sortChanged', { sortBy: 'storage', sortDesc: false });
      await waitForPromises();
      expect(getProjectListStorageHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          sortKey: 'STORAGE_SIZE_ASC',
        }),
      );
    });

    it('ignores invalid sorting types', async () => {
      findProjectList().vm.$emit('sortChanged', { sortBy: 'yellow', sortDesc: false });
      await waitForPromises();
      expect(getProjectListStorageHandler).toHaveBeenCalledTimes(1);
    });
  });

  describe('filtering projects', () => {
    const sampleSearchTerm = 'GitLab';

    beforeEach(() => {
      createComponent();
    });

    it('triggers search if user enters search input', async () => {
      expect(getProjectListStorageHandler).toHaveBeenNthCalledWith(
        1,
        expect.objectContaining({ searchTerm: '' }),
      );
      findSearchAndSortBar().vm.$emit('onFilter', sampleSearchTerm);
      await waitForPromises();

      expect(getProjectListStorageHandler).toHaveBeenNthCalledWith(
        2,
        expect.objectContaining({ searchTerm: sampleSearchTerm }),
      );
    });

    it('triggers search if user clears the entered search input', async () => {
      findSearchAndSortBar().vm.$emit('onFilter', sampleSearchTerm);
      await waitForPromises();

      expect(getProjectListStorageHandler).toHaveBeenCalledWith(
        expect.objectContaining({ searchTerm: sampleSearchTerm }),
      );

      findSearchAndSortBar().vm.$emit('onFilter', '');
      await waitForPromises();

      expect(getProjectListStorageHandler).toHaveBeenCalledWith(
        expect.objectContaining({ searchTerm: '' }),
      );
    });

    it('triggers search with empty string if user enters short search input', async () => {
      findSearchAndSortBar().vm.$emit('onFilter', sampleSearchTerm);
      await waitForPromises();
      expect(getProjectListStorageHandler).toHaveBeenCalledWith(
        expect.objectContaining({ searchTerm: sampleSearchTerm }),
      );

      const sampleShortSearchTerm = 'Gi';
      findSearchAndSortBar().vm.$emit('onFilter', sampleShortSearchTerm);
      await waitForPromises();

      expect(getProjectListStorageHandler).toHaveBeenCalledWith(
        expect.objectContaining({ searchTerm: '' }),
      );
    });
  });

  describe('projects table pagination component', () => {
    const projectsStorageWithPageInfo = cloneDeep(mockGetProjectListStorageGraphQLResponse);
    projectsStorageWithPageInfo.data.namespace.projects.pageInfo.hasNextPage = true;

    beforeEach(() => {
      getProjectListStorageHandler.mockResolvedValue(projectsStorageWithPageInfo);
    });

    it('has "Prev" button disabled', async () => {
      createComponent();
      await waitForPromises();

      expect(findPrevButton().attributes().disabled).toBe('disabled');
    });

    it('has "Next" button enabled', async () => {
      createComponent();
      await waitForPromises();

      expect(findNextButton().attributes().disabled).toBeUndefined();
    });

    describe('apollo calls', () => {
      beforeEach(async () => {
        projectsStorageWithPageInfo.data.namespace.projects.pageInfo.hasPreviousPage = true;
        createComponent();

        await waitForPromises();
      });

      it('contains correct `first` and `last` values when clicking "Prev" button', () => {
        findPrevButton().trigger('click');
        expect(getProjectListStorageHandler).toHaveBeenCalledTimes(2);
        expect(getProjectListStorageHandler).toHaveBeenNthCalledWith(
          2,
          expect.objectContaining({ first: undefined, last: expect.any(Number) }),
        );
      });

      it('contains `first` value when clicking "Next" button', () => {
        findNextButton().trigger('click');
        expect(getProjectListStorageHandler).toHaveBeenCalledTimes(2);
        expect(getProjectListStorageHandler).toHaveBeenNthCalledWith(
          2,
          expect.objectContaining({ first: expect.any(Number) }),
        );
      });
    });

    describe('handling failed apollo requests', () => {
      beforeEach(async () => {
        getProjectListStorageHandler.mockRejectedValue(new Error('Network error!'));
        createComponent();
        await waitForPromises();
      });

      it('shows gl-alert with error message', () => {
        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe(
          'An error occured while loading the storage usage details. Please refresh the page to try again.',
        );
      });

      it('captures the exception in Sentry', async () => {
        await Vue.nextTick();
        expect(captureException).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('storage-usage-statistics', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders the new storage design', () => {
      expect(findStorageUsageStatistics().exists()).toBe(true);
    });

    it('passes costFactoredStorageSize as usedStorage', () => {
      expect(findStorageUsageStatistics().props('usedStorage')).toBe(
        mockGetNamespaceStorageGraphQLResponse.data.namespace.rootStorageStatistics
          .costFactoredStorageSize,
      );
    });

    it('displays loading state', async () => {
      getNamespaceStorageHandler.mockImplementation(() => new Promise(() => {}));
      createComponent();
      await waitForPromises();
      expect(findStorageUsageStatistics().props('loading')).toBe(true);
    });
  });

  // https://docs.gitlab.com/ee/user/usage_quotas#project-storage-limit
  describe('Namespace under Project type storage enforcement', () => {
    it('sets default sorting to STORAGE_SIZE_DESC, when the limit is NOT set', () => {
      createComponent({
        provide: {
          isUsingNamespaceEnforcement: false,
          isUsingProjectEnforcementWithNoLimits: true,
        },
      });

      expect(getProjectListStorageHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          sortKey: 'STORAGE_SIZE_DESC',
        }),
      );

      const projectList = findProjectList();
      expect(projectList.props('sortBy')).toBe('storage');
      expect(projectList.props('sortDesc')).toBe(true);
    });

    it('sets default sorting to STORAGE, when the limit is set', () => {
      createComponent({
        provide: {
          isUsingNamespaceEnforcement: false,
          isUsingProjectEnforcementWithLimits: true,
        },
      });

      expect(getProjectListStorageHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          sortKey: 'STORAGE',
        }),
      );

      const projectList = findProjectList();
      expect(projectList.props('sortBy')).toBe(null);
      expect(projectList.props('sortDesc')).toBe(true);
    });
  });
});

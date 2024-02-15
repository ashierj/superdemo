import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import List from 'ee_component/packages_and_registries/google_artifact_registry/pages/list.vue';
import ListHeader from 'ee_component/packages_and_registries/google_artifact_registry/components/list/header.vue';
import ListTable from 'ee_component/packages_and_registries/google_artifact_registry/components/list/table.vue';
import getArtifactsQuery from 'ee_component/packages_and_registries/google_artifact_registry/graphql/queries/get_artifacts.query.graphql';
import { headerData, getArtifactsQueryResponse, imageData } from '../mock_data';

Vue.use(VueApollo);

describe('List', () => {
  let apolloProvider;
  let wrapper;

  const defaultProvide = {
    fullPath: 'gitlab-org/gitlab',
  };

  const findListHeader = () => wrapper.findComponent(ListHeader);
  const findListTable = () => wrapper.findComponent(ListTable);

  const createComponent = ({
    resolver = jest.fn().mockResolvedValue(getArtifactsQueryResponse),
  } = {}) => {
    const requestHandlers = [[getArtifactsQuery, resolver]];

    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMount(List, {
      apolloProvider,
      provide: defaultProvide,
    });
  };

  it('calls apollo query with sort params', async () => {
    const resolver = jest.fn().mockResolvedValue(getArtifactsQueryResponse);
    createComponent({ resolver });
    await waitForPromises();

    expect(resolver).toHaveBeenCalledTimes(1);
    expect(resolver).toHaveBeenNthCalledWith(
      1,
      expect.objectContaining({
        first: 20,
        fullPath: 'gitlab-org/gitlab',
        sort: 'UPDATE_TIME_DESC',
      }),
    );
  });

  describe('list header', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the list header with loading prop', () => {
      expect(findListHeader().props()).toMatchObject({
        data: {},
        isLoading: true,
        showError: false,
      });
    });

    it('renders the list header with data prop', async () => {
      await waitForPromises();

      expect(findListHeader().props()).toMatchObject({
        data: headerData,
        isLoading: false,
        showError: false,
      });
    });

    it('renders the list header with error prop', async () => {
      const resolver = jest.fn().mockRejectedValue(new Error('error'));
      createComponent({ resolver });
      await waitForPromises();

      expect(findListHeader().props()).toMatchObject({
        data: {},
        isLoading: false,
        showError: true,
      });
    });
  });

  describe('list table', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the list table with loading prop', () => {
      expect(findListTable().props()).toMatchObject({
        data: {},
        isLoading: true,
      });
    });

    it('renders the list table with data prop', async () => {
      await waitForPromises();

      expect(findListTable().props()).toMatchObject({
        data: { nodes: [imageData] },
        isLoading: false,
      });
    });

    it('hides the list table when resolve fails error', async () => {
      const resolver = jest.fn().mockRejectedValue(new Error('error'));
      createComponent({ resolver });
      await waitForPromises();

      expect(findListTable().exists()).toBe(false);
    });

    it('renders the list table with sort prop', () => {
      expect(findListTable().props('sort')).toEqual({
        sortBy: 'updateTime',
        sortDesc: true,
      });
    });

    describe('when table emits sort-changed event', () => {
      const resolver = jest.fn().mockResolvedValue(getArtifactsQueryResponse);
      beforeEach(async () => {
        createComponent({ resolver });

        await waitForPromises();

        findListTable().vm.$emit('sort-changed', { sortBy: 'updateTime', sortDesc: false });
      });

      it('updates sort', async () => {
        await nextTick();

        expect(findListTable().props('sort')).toEqual({
          sortBy: 'updateTime',
          sortDesc: false,
        });
      });

      it('calls apollo query with updated sort params', async () => {
        await waitForPromises();

        expect(resolver).toHaveBeenCalledTimes(2);
        expect(resolver).toHaveBeenNthCalledWith(
          2,
          expect.objectContaining({
            sort: 'UPDATE_TIME_ASC',
          }),
        );
      });
    });
  });
});

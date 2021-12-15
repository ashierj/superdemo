import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { resolvers } from '~/environments/graphql/resolvers';
import environmentToRollback from '~/environments/graphql/queries/environment_to_rollback.query.graphql';
import environmentToDelete from '~/environments/graphql/queries/environment_to_delete.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import pollIntervalQuery from '~/environments/graphql/queries/poll_interval.query.graphql';
import { TEST_HOST } from 'helpers/test_constants';
import {
  environmentsApp,
  resolvedEnvironmentsApp,
  resolvedEnvironment,
  folder,
  resolvedFolder,
} from './mock_data';

const ENDPOINT = `${TEST_HOST}/environments`;

describe('~/frontend/environments/graphql/resolvers', () => {
  let mockResolvers;
  let mock;
  let mockApollo;
  let localState;

  beforeEach(() => {
    mockResolvers = resolvers(ENDPOINT);
    mock = new MockAdapter(axios);
    mockApollo = createMockApollo();
    localState = mockApollo.defaultClient.localState;
  });

  afterEach(() => {
    mock.reset();
  });

  describe('environmentApp', () => {
    it('should fetch environments and map them to frontend data', async () => {
      const cache = { writeQuery: jest.fn() };
      const scope = 'available';
      mock.onGet(ENDPOINT, { params: { nested: true, scope } }).reply(200, environmentsApp, {});

      const app = await mockResolvers.Query.environmentApp(null, { scope }, { cache });
      expect(app).toEqual(resolvedEnvironmentsApp);
      expect(cache.writeQuery).toHaveBeenCalledWith({
        query: pollIntervalQuery,
        data: { interval: undefined },
      });
    });
    it('should set the poll interval when there is one', async () => {
      const cache = { writeQuery: jest.fn() };
      const scope = 'stopped';
      mock
        .onGet(ENDPOINT, { params: { nested: true, scope } })
        .reply(200, environmentsApp, { 'poll-interval': 3000 });

      await mockResolvers.Query.environmentApp(null, { scope }, { cache });
      expect(cache.writeQuery).toHaveBeenCalledWith({
        query: pollIntervalQuery,
        data: { interval: 3000 },
      });
    });
  });
  describe('folder', () => {
    it('should fetch the folder url passed to it', async () => {
      mock.onGet(ENDPOINT, { params: { per_page: 3 } }).reply(200, folder);

      const environmentFolder = await mockResolvers.Query.folder(null, {
        environment: { folderPath: ENDPOINT },
      });

      expect(environmentFolder).toEqual(resolvedFolder);
    });
  });
  describe('stopEnvironment', () => {
    it('should post to the stop environment path', async () => {
      mock.onPost(ENDPOINT).reply(200);

      await mockResolvers.Mutation.stopEnvironment(null, { environment: { stopPath: ENDPOINT } });

      expect(mock.history.post).toContainEqual(
        expect.objectContaining({ url: ENDPOINT, method: 'post' }),
      );
    });
  });
  describe('rollbackEnvironment', () => {
    it('should post to the retry environment path', async () => {
      mock.onPost(ENDPOINT).reply(200);

      await mockResolvers.Mutation.rollbackEnvironment(null, {
        environment: { retryUrl: ENDPOINT },
      });

      expect(mock.history.post).toContainEqual(
        expect.objectContaining({ url: ENDPOINT, method: 'post' }),
      );
    });
  });
  describe('deleteEnvironment', () => {
    it('should DELETE to the delete environment path', async () => {
      mock.onDelete(ENDPOINT).reply(200);

      await mockResolvers.Mutation.deleteEnvironment(null, {
        environment: { deletePath: ENDPOINT },
      });

      expect(mock.history.delete).toContainEqual(
        expect.objectContaining({ url: ENDPOINT, method: 'delete' }),
      );
    });
  });
  describe('cancelAutoStop', () => {
    it('should post to the auto stop path', async () => {
      mock.onPost(ENDPOINT).reply(200);

      await mockResolvers.Mutation.cancelAutoStop(null, {
        environment: { autoStopPath: ENDPOINT },
      });

      expect(mock.history.post).toContainEqual(
        expect.objectContaining({ url: ENDPOINT, method: 'post' }),
      );
    });
  });
  describe('setEnvironmentToRollback', () => {
    it('should write the given environment to the cache', () => {
      localState.client.writeQuery = jest.fn();
      mockResolvers.Mutation.setEnvironmentToRollback(
        null,
        { environment: resolvedEnvironment },
        localState,
      );

      expect(localState.client.writeQuery).toHaveBeenCalledWith({
        query: environmentToRollback,
        data: { environmentToRollback: resolvedEnvironment },
      });
    });
  });
  describe('setEnvironmentToDelete', () => {
    it('should write the given environment to the cache', () => {
      localState.client.writeQuery = jest.fn();
      mockResolvers.Mutation.setEnvironmentToDelete(
        null,
        { environment: resolvedEnvironment },
        localState,
      );

      expect(localState.client.writeQuery).toHaveBeenCalledWith({
        query: environmentToDelete,
        data: { environmentToDelete: resolvedEnvironment },
      });
    });
  });
});

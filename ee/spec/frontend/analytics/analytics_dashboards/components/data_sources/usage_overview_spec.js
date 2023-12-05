import {
  USAGE_OVERVIEW_METADATA,
  USAGE_OVERVIEW_IDENTIFIER_GROUPS,
  USAGE_OVERVIEW_IDENTIFIER_PROJECTS,
  USAGE_OVERVIEW_IDENTIFIER_ISSUES,
  USAGE_OVERVIEW_IDENTIFIER_MERGE_REQUESTS,
  USAGE_OVERVIEW_IDENTIFIER_PIPELINES,
} from '~/analytics/shared/constants';
import {
  fetch,
  prepareQuery,
  extractUsageMetrics,
} from 'ee/analytics/analytics_dashboards/data_sources/usage_overview';
import { defaultClient } from 'ee/analytics/analytics_dashboards/graphql/client';
import {
  mockUsageMetricsQueryResponse,
  mockUsageMetrics,
  mockUsageMetricsNoData,
} from '../../mock_data';

describe('Usage overview Data Source', () => {
  let obj;

  const namespace = { name: 'cool namespace', requestPath: 'some-group-path' };
  const queryKeys = [USAGE_OVERVIEW_IDENTIFIER_GROUPS, USAGE_OVERVIEW_IDENTIFIER_MERGE_REQUESTS];
  const mockQuery = { include: queryKeys };
  const { group: mockGroupUsageMetricsQueryResponse } = mockUsageMetricsQueryResponse;
  const identifiers = [
    USAGE_OVERVIEW_IDENTIFIER_GROUPS,
    USAGE_OVERVIEW_IDENTIFIER_PROJECTS,
    USAGE_OVERVIEW_IDENTIFIER_ISSUES,
    USAGE_OVERVIEW_IDENTIFIER_MERGE_REQUESTS,
    USAGE_OVERVIEW_IDENTIFIER_PIPELINES,
  ];

  describe('extractUsageMetrics', () => {
    it('returns an array of metrics', () => {
      expect(extractUsageMetrics(mockGroupUsageMetricsQueryResponse)).toEqual(mockUsageMetrics);
    });

    it('returns all the available metrics with their metadata', () => {
      const metrics = extractUsageMetrics(mockGroupUsageMetricsQueryResponse);

      metrics.forEach((metric) => {
        const { identifier, options } = metric;
        expect(identifiers.includes(identifier)).toBe(true);
        expect(metric.value).toBe(mockGroupUsageMetricsQueryResponse[identifier].count);
        expect(options).toBe(USAGE_OVERVIEW_METADATA[identifier].options);
      });
    });
  });

  describe('prepareQuery', () => {
    const queryIncludeKeys = [
      'includeGroups',
      'includeProjects',
      'includeIssues',
      'includeMergeRequests',
      'includePipelines',
    ];

    it('will return all the keys we can include', () => {
      expect(Object.keys(prepareQuery())).toEqual(queryIncludeKeys);
    });

    it('will return false for every key by default', () => {
      Object.values(prepareQuery()).forEach((res) => {
        expect(res).toBe(false);
      });
    });

    it('will set keys that are explicitly included to true', () => {
      const res = prepareQuery(queryKeys);

      expect(res).toEqual({
        includeGroups: true,
        includeIssues: false,
        includeProjects: false,
        includeMergeRequests: true,
        includePipelines: false,
      });
    });
  });

  describe('fetch', () => {
    it.each`
      label                 | namespaceParam
      ${'with a project'}   | ${{ requestPath: 'some-group/some-project' }}
      ${'with a sub group'} | ${{ requestPath: 'some-group/some-subgroup' }}
      ${'with a group'}     | ${{ requestPath: 'some-group' }}
    `('$label queries the top level group', async ({ namespaceParam }) => {
      jest.spyOn(defaultClient, 'query').mockResolvedValue({ data: {} });

      obj = await fetch({ namespace: namespaceParam, query: mockQuery });

      expect(defaultClient.query).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: {
            fullPath: 'some-group',
            startDate: expect.anything(),
            endDate: expect.anything(),
            includeGroups: true,
            includeMergeRequests: true,
            includeIssues: false,
            includeProjects: false,
            includePipelines: false,
          },
        }),
      );
    });

    it('will only request the specified metrics', async () => {
      jest.spyOn(defaultClient, 'query').mockResolvedValue({ data: {} });

      obj = await fetch({
        namespace,
        query: { include: [USAGE_OVERVIEW_IDENTIFIER_MERGE_REQUESTS] },
      });

      expect(defaultClient.query).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: {
            fullPath: 'some-group-path',
            startDate: expect.anything(),
            endDate: expect.anything(),
            includeMergeRequests: true,
            includeGroups: false,
            includeIssues: false,
            includeProjects: false,
            includePipelines: false,
          },
        }),
      );
    });

    it.each`
      label                              | data                             | params
      ${'with no data'}                  | ${{}}                            | ${{ namespace, query: mockQuery }}
      ${'with no namespace.requestPath'} | ${mockUsageMetricsQueryResponse} | ${{ namespace: {}, query: mockQuery }}
    `('$label returns the no data object', async ({ params }) => {
      jest.spyOn(defaultClient, 'query').mockResolvedValue({ data: {} });

      obj = await fetch(params);

      expect(obj).toMatchObject(mockUsageMetricsNoData);
    });

    describe('with an error', () => {
      beforeEach(() => {
        jest.spyOn(defaultClient, 'query').mockRejectedValue();

        obj = fetch({ namespace, query: mockQuery });
      });

      it('returns the no data object', async () => {
        await expect(() => obj).rejects.toThrow('Failed to load usage overview data');
      });
    });

    describe('successfully completes', () => {
      beforeEach(async () => {
        jest
          .spyOn(defaultClient, 'query')
          .mockResolvedValue({ data: mockUsageMetricsQueryResponse });

        obj = await fetch({ namespace, query: mockQuery });
      });

      it('will fetch the usage metrics', () => {
        expect(obj).toMatchObject(mockUsageMetrics);
      });
    });
  });
});

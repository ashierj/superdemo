import {
  filterToQueryObject,
  urlQueryToFilter,
  prepareTokens,
  processFilters,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

export const PERIOD_FILTER_TOKEN_TYPE = 'period';
export const SERVICE_NAME_FILTER_TOKEN_TYPE = 'service-name';
export const OPERATION_FILTER_TOKEN_TYPE = 'operation';
export const TRACE_ID_FILTER_TOKEN_TYPE = 'trace-id';
export const DURATION_MS_FILTER_TOKEN_TYPE = 'duration-ms';
export const ATTRIBUTE_FILTER_TOKEN_TYPE = 'attribute';

const DEFAULT_PERIOD_FILTER = [{ operator: '=', value: '1h' }];

export function queryToFilterObj(query) {
  const filter = urlQueryToFilter(query, {
    filteredSearchTermKey: 'search',
    customOperators: [
      {
        operator: '>',
        prefix: 'gt',
      },
      {
        operator: '<',
        prefix: 'lt',
      },
    ],
  });
  const {
    period = DEFAULT_PERIOD_FILTER,
    service = undefined,
    operation = undefined,
    trace_id: traceId = undefined,
    durationMs = undefined,
    attribute = undefined,
  } = filter;
  const search = filter[FILTERED_SEARCH_TERM];
  return {
    period,
    service,
    operation,
    traceId,
    durationMs,
    search,
    attribute,
  };
}

export function filterObjToQuery(filters) {
  return filterToQueryObject(
    {
      period: filters.period,
      service: filters.service,
      operation: filters.operation,
      trace_id: filters.traceId,
      durationMs: filters.durationMs,
      attribute: filters.attribute,
      [FILTERED_SEARCH_TERM]: filters.search,
    },
    {
      filteredSearchTermKey: 'search',
      customOperators: [
        {
          operator: '>',
          prefix: 'gt',
          applyOnlyToKey: 'durationMs',
        },
        {
          operator: '<',
          prefix: 'lt',
          applyOnlyToKey: 'durationMs',
        },
      ],
    },
  );
}

export function filterObjToFilterToken(filters) {
  return prepareTokens({
    [PERIOD_FILTER_TOKEN_TYPE]: filters.period,
    [SERVICE_NAME_FILTER_TOKEN_TYPE]: filters.service,
    [OPERATION_FILTER_TOKEN_TYPE]: filters.operation,
    [TRACE_ID_FILTER_TOKEN_TYPE]: filters.traceId,
    [DURATION_MS_FILTER_TOKEN_TYPE]: filters.durationMs,
    [ATTRIBUTE_FILTER_TOKEN_TYPE]: filters.attribute,
    [FILTERED_SEARCH_TERM]: filters.search,
  });
}

export function filterTokensToFilterObj(tokens) {
  const {
    [SERVICE_NAME_FILTER_TOKEN_TYPE]: service,
    [PERIOD_FILTER_TOKEN_TYPE]: period = DEFAULT_PERIOD_FILTER,
    [OPERATION_FILTER_TOKEN_TYPE]: operation,
    [TRACE_ID_FILTER_TOKEN_TYPE]: traceId,
    [DURATION_MS_FILTER_TOKEN_TYPE]: durationMs,
    [ATTRIBUTE_FILTER_TOKEN_TYPE]: attribute,
    [FILTERED_SEARCH_TERM]: search,
  } = processFilters(tokens);

  return {
    service,
    period,
    operation,
    traceId,
    durationMs,
    attribute,
    search,
  };
}

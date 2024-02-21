import { omit } from 'lodash';
import {
  filterToQueryObject,
  urlQueryToFilter,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import {
  OPERERATOR_LIKE,
  OPERERATOR_NOT_LIKE,
  CUSTOM_DATE_RANGE_OPTION,
} from '~/observability/constants';
import { queryToObject } from '~/lib/utils/url_utility';
import { isValidDate } from '~/lib/utils/datetime_utility';

const DEFAULT_TIME_RANGE = '1h';
const FILTERED_SEARCH_TERM_KEY = 'search';

const customOperators = [
  {
    operator: OPERERATOR_LIKE,
    prefix: 'like',
  },
  {
    operator: OPERERATOR_NOT_LIKE,
    prefix: 'not_like',
  },
];

const GROUP_BY_FN_QUERY_KEY = 'group_by_fn';
const GROUP_BY_ATTRIBUTES_QUERY_KEY = 'group_by_attrs';
const DATE_RANGE_QUERY_KEY = 'date_range';
const DATE_RANGE_START_QUERY_KEY = 'date_start';
const DATE_RANGE_END_QUERY_KEY = 'date_end';

export function filterObjToQuery(filters) {
  const attributes = filterToQueryObject(filters.attributes, {
    filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
    customOperators,
  });
  return {
    ...attributes,
    [GROUP_BY_FN_QUERY_KEY]: filters.groupBy?.func,
    [GROUP_BY_ATTRIBUTES_QUERY_KEY]: filters.groupBy?.attributes?.length
      ? filters.groupBy.attributes
      : undefined,
    [DATE_RANGE_QUERY_KEY]: filters.dateRange?.value,
    ...(filters.dateRange?.value === CUSTOM_DATE_RANGE_OPTION
      ? {
          [DATE_RANGE_START_QUERY_KEY]: filters.dateRange?.startDate?.toISOString(),
          [DATE_RANGE_END_QUERY_KEY]: filters.dateRange?.endDate?.toISOString(),
        }
      : {}),
  };
}

function validatedDateRangeQuery(dateRangeValue, dateRangeStart, dateRangeEnd) {
  if (dateRangeValue === CUSTOM_DATE_RANGE_OPTION) {
    if (isValidDate(new Date(dateRangeStart)) && isValidDate(new Date(dateRangeEnd))) {
      return {
        value: dateRangeValue,
        startDate: new Date(dateRangeStart),
        endDate: new Date(dateRangeEnd),
      };
    }
    return {
      value: DEFAULT_TIME_RANGE,
    };
  }
  return {
    value: dateRangeValue ?? DEFAULT_TIME_RANGE,
  };
}

function validatedGroupByAttributes(groupByAttributes = []) {
  const nonEmptyAttrs = groupByAttributes.filter((attr) => attr.length > 0);
  return nonEmptyAttrs.length > 0 ? nonEmptyAttrs : undefined;
}

export function queryToFilterObj(queryString) {
  const queryObj = queryToObject(queryString, { gatherArrays: true });
  const {
    [GROUP_BY_FN_QUERY_KEY]: groupByFn,
    [GROUP_BY_ATTRIBUTES_QUERY_KEY]: groupByAttributes,
    [DATE_RANGE_QUERY_KEY]: dateRangeValue,
    [DATE_RANGE_START_QUERY_KEY]: dateRangeStart,
    [DATE_RANGE_END_QUERY_KEY]: dateRangeEnd,
    ...attributes
  } = omit(queryObj, [
    // not all query params are filters, so omitting them from the query object
    'type',
  ]);

  const attributesFilter = urlQueryToFilter(attributes, {
    filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
    customOperators,
  });

  return {
    attributes: attributesFilter,
    groupBy: {
      func: groupByFn,
      attributes: validatedGroupByAttributes(groupByAttributes),
    },
    dateRange: validatedDateRangeQuery(dateRangeValue, dateRangeStart, dateRangeEnd),
  };
}

import {
  filterToQueryObject,
  urlQueryToFilter,
  prepareTokens,
  processFilters,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

export const ATTRIBUTE_FILTER_TOKEN_TYPE = 'attribute';

export function queryToFilterObj(query) {
  const filter = urlQueryToFilter(query, {
    filteredSearchTermKey: 'search',
  });
  const { attribute = undefined } = filter;
  const search = filter[FILTERED_SEARCH_TERM];
  return {
    attribute,
    search,
  };
}

export function filterObjToQuery(filters) {
  return filterToQueryObject(
    {
      [FILTERED_SEARCH_TERM]: filters.search,
      [ATTRIBUTE_FILTER_TOKEN_TYPE]: filters.attribute,
    },
    {
      filteredSearchTermKey: 'search',
    },
  );
}

export function filterObjToFilterToken(filters) {
  return prepareTokens({
    [FILTERED_SEARCH_TERM]: filters.search,
    [ATTRIBUTE_FILTER_TOKEN_TYPE]: filters.attribute,
  });
}

export function filterTokensToFilterObj(tokens) {
  const {
    [FILTERED_SEARCH_TERM]: search,
    [ATTRIBUTE_FILTER_TOKEN_TYPE]: attribute,
  } = processFilters(tokens);

  return {
    search,
    attribute,
  };
}

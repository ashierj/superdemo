import {
  filterToQueryObject,
  urlQueryToFilter,
  prepareTokens,
  processFilters,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

export function queryToFilterObj(query) {
  const filter = urlQueryToFilter(query, {
    filteredSearchTermKey: 'search',
  });
  const search = filter[FILTERED_SEARCH_TERM];
  return {
    search,
  };
}

export function filterObjToQuery(filters) {
  return filterToQueryObject(
    {
      [FILTERED_SEARCH_TERM]: filters.search,
    },
    {
      filteredSearchTermKey: 'search',
    },
  );
}

export function filterObjToFilterToken(filters) {
  return prepareTokens({
    [FILTERED_SEARCH_TERM]: filters.search,
  });
}

export function filterTokensToFilterObj(tokens) {
  const { [FILTERED_SEARCH_TERM]: search } = processFilters(tokens);

  return {
    search,
  };
}

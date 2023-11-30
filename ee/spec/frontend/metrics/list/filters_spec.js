import {
  queryToFilterObj,
  filterObjToQuery,
  filterObjToFilterToken,
  filterTokensToFilterObj,
} from 'ee/metrics/list/filters';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

describe('queryToFilterObj', () => {
  it('converts query to filter obj', () => {
    expect(queryToFilterObj('search=foo+bar&unsupportedFilter=foo')).toEqual({
      search: [{ value: 'foo bar' }],
    });
  });
  it('handles empty query', () => {
    expect(queryToFilterObj('')).toEqual({ search: undefined });
  });
});

describe('filterObjToQuery', () => {
  it('converts a filter object to a query object', () => {
    expect(
      filterObjToQuery({
        search: [{ value: 'foo bar' }],
        unsupportedFilter: [{ value: 'foo' }],
      }),
    ).toEqual({ search: 'foo bar' });
  });
});

describe('filterObjToFilterToken', () => {
  it('converts filter object to filter token', () => {
    expect(
      filterObjToFilterToken({
        search: [{ value: 'foo bar' }],
        unsupportedFilter: [{ value: 'foo' }],
      }),
    ).toEqual([{ type: FILTERED_SEARCH_TERM, value: { data: 'foo bar', operator: undefined } }]);
  });
});

describe('filterTokensToFilterObj', () => {
  it('converts filter token to filter obj', () => {
    expect(
      filterTokensToFilterObj([
        { type: FILTERED_SEARCH_TERM, value: { data: 'foo bar', operator: undefined } },
        { type: 'unsupported-filter', value: { data: 'foo', operator: undefined } },
      ]),
    ).toEqual({ search: [{ value: 'foo bar' }] });
  });
});

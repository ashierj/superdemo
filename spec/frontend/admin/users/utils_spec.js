import { TOKENS } from '~/admin/users/constants';
import { initializeValuesFromQuery } from '~/admin/users/utils';

const allFilters = TOKENS.flatMap(({ type, options, operators }) =>
  options.map(({ value }) => ({ value, type, operator: operators[0].value })),
);

describe('initializeValuesFromQuery', () => {
  it('parses `search_query` query parameter correctly', () => {
    expect(initializeValuesFromQuery('?search_query=dummy')).toMatchObject({
      tokens: ['dummy'],
      sort: undefined,
    });
  });

  it.each(allFilters)('parses `filter` query parameter `$value`', ({ value, type, operator }) => {
    expect(initializeValuesFromQuery(`?search_query=dummy&filter=${value}`)).toMatchObject({
      tokens: [{ type, value: { data: value, operator } }, 'dummy'],
      sort: undefined,
    });
  });

  it('parses `sort` query parameter correctly', () => {
    expect(initializeValuesFromQuery('?sort=last_activity_on_asc')).toMatchObject({
      tokens: [],
      sort: 'last_activity_on_asc',
    });
  });

  it('ignores `filter` query parameter not found in the TOKEN options', () => {
    expect(initializeValuesFromQuery('?filter=unknown')).toMatchObject({
      tokens: [],
      sort: undefined,
    });
  });

  it('ignores other query parameters other than `filter` and `search_query` and `sort`', () => {
    expect(initializeValuesFromQuery('?other=value')).toMatchObject({
      tokens: [],
      sort: undefined,
    });
  });
});

import { filterObjToFilterToken, filterTokensToFilterObj } from 'ee/logs/list/filter_bar/filters';

describe('utils', () => {
  const filterObj = {
    service: [
      { operator: '=', value: 'serviceName' },
      { operator: '!=', value: 'serviceName2' },
    ],
    severityName: [
      { operator: '=', value: 'info' },
      { operator: '!=', value: 'warning' },
    ],
    traceId: [{ operator: '=', value: 'traceId' }],
    spanId: [{ operator: '=', value: 'spanId' }],
    fingerprint: [{ operator: '=', value: 'fingerprint' }],
    traceFlags: [
      { operator: '=', value: '1' },
      { operator: '!=', value: '2' },
    ],
    attribute: [{ operator: '=', value: 'attr=bar' }],
    resourceAttribute: [{ operator: '=', value: 'res=foo' }],
    search: [{ value: 'some-search' }],
  };

  const filterTokens = [
    {
      type: 'service-name',
      value: { data: 'serviceName', operator: '=' },
    },
    {
      type: 'service-name',
      value: { data: 'serviceName2', operator: '!=' },
    },
    { type: 'severity-name', value: { data: 'info', operator: '=' } },
    { type: 'severity-name', value: { data: 'warning', operator: '!=' } },
    { type: 'trace-id', value: { data: 'traceId', operator: '=' } },
    { type: 'span-id', value: { data: 'spanId', operator: '=' } },
    {
      type: 'fingerprint',
      value: { data: 'fingerprint', operator: '=' },
    },
    { type: 'trace-flags', value: { data: '1', operator: '=' } },
    { type: 'trace-flags', value: { data: '2', operator: '!=' } },
    { type: 'attribute', value: { data: 'attr=bar', operator: '=' } },
    {
      type: 'resource-attribute',
      value: { data: 'res=foo', operator: '=' },
    },
    {
      type: 'filtered-search-term',
      value: { data: 'some-search', operator: undefined },
    },
  ];

  describe('filterObjToFilterToken', () => {
    it('should convert filter object to filter tokens', () => {
      expect(filterObjToFilterToken(filterObj)).toEqual(filterTokens);
    });
  });

  describe('filterTokensToFilterObj', () => {
    it('should convert filter tokens to filter object', () => {
      expect(filterTokensToFilterObj(filterTokens)).toEqual(filterObj);
    });
  });
});

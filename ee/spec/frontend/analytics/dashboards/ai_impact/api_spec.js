import { extractGraphqlAiData } from 'ee/analytics/dashboards/ai_impact/api';

describe('AI impact dashboard api', () => {
  describe('extractGraphqlAiData', () => {
    it('returns `-` when the payload is undefined', () => {
      expect(extractGraphqlAiData()).toEqual({
        code_suggestions_usage_rate: {
          identifier: 'code_suggestions_usage_rate',
          value: '-',
        },
      });
    });

    it('returns `-` when the value is undefined', () => {
      expect(extractGraphqlAiData({ codeSuggestionsUsageRate: undefined })).toEqual({
        code_suggestions_usage_rate: {
          identifier: 'code_suggestions_usage_rate',
          value: '-',
        },
      });
    });

    it('formats the value for the table', () => {
      const value = 33.33;
      expect(extractGraphqlAiData({ codeSuggestionsUsageRate: value })).toEqual({
        code_suggestions_usage_rate: {
          identifier: 'code_suggestions_usage_rate',
          value,
        },
      });
    });
  });
});

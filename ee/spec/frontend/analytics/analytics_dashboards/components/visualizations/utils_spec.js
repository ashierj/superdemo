import { formatVisualizationValue } from 'ee/analytics/analytics_dashboards/components/visualizations/utils';

describe('formatVisualizationValue', () => {
  describe('when the value is not numeric', () => {
    it.each(['abc', true, null, undefined])('returns the value without modification', (value) => {
      expect(formatVisualizationValue(value)).toBe(value);
    });
  });

  describe('when the value is a date string', () => {
    it.each(['2023-11-15T00:00:00.000', '2023-11-15'])(
      'returns the value without modification',
      (value) => {
        expect(formatVisualizationValue(value)).toBe(value);
      },
    );
  });

  describe('when the value is numeric', () => {
    it.each([
      [123, '123'],
      [1234, '1,234'],
      [-123, '-123'],
      [123.12, '123'],
      [-1234.12, '-1,234'],
      ['1234567890', '1,234,567,890'],
      ['1234567890.123456', '1,234,567,890'],
      ['-1234567890', '-1,234,567,890'],
      ['-1234567890.123456', '-1,234,567,890'],
    ])('returns the formatted value', (value, expected) => {
      expect(formatVisualizationValue(value)).toBe(expected);
    });
  });
});

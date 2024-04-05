import {
  generateDateRanges,
  generateTableColumns,
  generateSkeletonTableData,
  generateTableRows,
} from 'ee/analytics/dashboards/ai_impact/utils';
import { mockDoraTimePeriods } from './mock_data';

describe('AI impact Dashboard utils', () => {
  describe('generateDateRanges', () => {
    it.each`
      date            | description
      ${'07-01-2021'} | ${'on the first of the month'}
      ${'03-31-2021'} | ${'on the last of the month'}
      ${'03-31-2020'} | ${'in a leap year'}
    `('returns the expected date ranges $description', ({ date }) => {
      expect(generateDateRanges(new Date(date))).toMatchSnapshot();
    });
  });

  describe('generateTableColumns', () => {
    it.each`
      date            | description
      ${'07-01-2021'} | ${'on the first of the month'}
      ${'03-31-2021'} | ${'on the last of the month'}
      ${'03-31-2020'} | ${'in a leap year'}
    `('returns the expected table fields $description', ({ date }) => {
      expect(generateTableColumns(new Date(date))).toMatchSnapshot();
    });
  });

  describe('generateSkeletonTableData', () => {
    it('returns the skeleton based on the table fields', () => {
      expect(generateSkeletonTableData()).toMatchSnapshot();
    });
  });

  describe('generateTableRows', () => {
    it('returns the data formatted as a table row', () => {
      expect(generateTableRows(mockDoraTimePeriods)).toMatchSnapshot();
    });
  });
});

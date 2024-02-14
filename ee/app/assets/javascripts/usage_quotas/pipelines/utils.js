import { parseBoolean } from '~/lib/utils/common_utils';
import { dateToYearMonthDate, newDateAsLocaleTime } from '~/lib/utils/datetime_utility';

const formatMonthData = (cur) => {
  const date = newDateAsLocaleTime(cur.monthIso8601);
  const formattedDate = dateToYearMonthDate(date);

  return {
    date,
    ...formattedDate,
    ...cur,
  };
};

export const getUsageDataByYearAsArray = (ciMinutesUsage) => {
  return ciMinutesUsage.reduce((acc, cur) => {
    const formattedData = formatMonthData(cur);

    if (acc[formattedData.year] != null) {
      acc[formattedData.year].push(formattedData);
    } else {
      acc[formattedData.year] = [formattedData];
    }
    return acc;
  }, {});
};

export const getUsageDataByYearByMonthAsObject = (ciMinutesUsage) => {
  return ciMinutesUsage.reduce((acc, cur) => {
    const formattedData = formatMonthData(cur);

    if (!acc[formattedData.year]) {
      acc[formattedData.year] = {};
    }

    acc[formattedData.year][formattedData.date.getMonth()] = formattedData;
    return acc;
  }, {});
};

/**
 * Formats date to `yyyy-mm-dd`
 * @param { number } year full year
 * @param { number } monthIndex month index, between 0 and 11
 * @param { number } day day of the month
 * @returns { string } formatted date string
 *
 * NOTE: it might be worth moving this utility to date time utils
 * in ~/lib/utils/datetime_utility.js
 */
export const formatIso8601Date = (year, monthIndex, day) => {
  return [year, monthIndex + 1, day]
    .map(String)
    .map((s) => s.padStart(2, '0'))
    .join('-');
};

export const parseProvideData = (el) => {
  if (!el) {
    return {};
  }

  const {
    pageSize,
    namespacePath,
    namespaceId,
    namespaceActualPlanName,
    userNamespace,
    ciMinutesAnyProjectEnabled,
    ciMinutesDisplayMinutesAvailableData,
    ciMinutesLastResetDate,
    ciMinutesMonthlyMinutesLimit,
    ciMinutesMonthlyMinutesUsed,
    ciMinutesMonthlyMinutesUsedPercentage,
    ciMinutesPurchasedMinutesLimit,
    ciMinutesPurchasedMinutesUsed,
    ciMinutesPurchasedMinutesUsedPercentage,
    buyAdditionalMinutesPath,
    buyAdditionalMinutesTarget,
  } = el.dataset;

  return {
    pageSize: Number(pageSize),
    namespacePath,
    namespaceId,
    namespaceActualPlanName,
    userNamespace: parseBoolean(userNamespace),
    ciMinutesAnyProjectEnabled: parseBoolean(ciMinutesAnyProjectEnabled),
    ciMinutesDisplayMinutesAvailableData: parseBoolean(ciMinutesDisplayMinutesAvailableData),
    ciMinutesLastResetDate,
    // Limit and Usage could be a number or a string (e.g. `Unlimited`) so we shouldn't parse these
    ciMinutesMonthlyMinutesLimit,
    ciMinutesMonthlyMinutesUsed,
    ciMinutesMonthlyMinutesUsedPercentage,
    ciMinutesPurchasedMinutesLimit,
    ciMinutesPurchasedMinutesUsed,
    ciMinutesPurchasedMinutesUsedPercentage,
    buyAdditionalMinutesPath,
    buyAdditionalMinutesTarget,
  };
};

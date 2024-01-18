import {
  getTimeago,
  timeagoLanguageCode,
  DEFAULT_DATE_TIME_FORMAT,
} from '~/lib/utils/datetime_utility';

export function ingestedAtTimeAgo(ingestedAtNano) {
  const timeago = getTimeago(DEFAULT_DATE_TIME_FORMAT);
  return timeago.format(ingestedAtNano / 1000000, timeagoLanguageCode);
}

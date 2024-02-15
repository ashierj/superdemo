import { isNumeric } from '~/lib/utils/number_utils';
import { formatNumber } from '~/locale';
import { isValidDateString } from '~/lib/utils/datetime_range';

export function formatVisualizationValue(value) {
  if (isValidDateString(value)) {
    return value;
  }

  if (isNumeric(value)) {
    return formatNumber(parseInt(value, 10));
  }

  return value;
}

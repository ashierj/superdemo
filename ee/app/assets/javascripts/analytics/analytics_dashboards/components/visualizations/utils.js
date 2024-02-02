import { isNumeric } from '~/lib/utils/number_utils';
import { formatNumber } from '~/locale';

export function formatVisualizationValue(value) {
  if (isNumeric(value)) {
    return formatNumber(parseInt(value, 10));
  }

  return value;
}

import { AI_METRICS } from '~/analytics/shared/constants';

/**
 * @typedef {Object} TableMetric
 * @property {String} identifier - Identifier for the specified metric
 * @property {String} value - Display friendly value
 */

/**
 * @typedef {Object} AiMetricItem
 * @property {Float} codeSuggestionsUsageRate - Usage rate %
 */

/**
 * @typedef {Object} AiMetricResponseItem
 * @property {TableMetric} code_suggestions_usage_rate
 */

/**
 * Takes the raw `aiMetrics` graphql response and prepares the data for display
 * in the tiled column chart.
 *
 * @param {AiMetricItem} data
 * @returns {AiMetricResponseItem} AI metrics ready for rendering in the dashboard
 */
export const extractGraphqlAiData = ({ codeSuggestionsUsageRate = '-' } = {}) => ({
  [AI_METRICS.CODE_SUGGESTIONS_USAGE_RATE]: {
    identifier: AI_METRICS.CODE_SUGGESTIONS_USAGE_RATE,
    value: codeSuggestionsUsageRate,
  },
});

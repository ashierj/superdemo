import { parse } from 'yaml';
import Api from '~/api';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import { YAML_CONFIG_PATH, BUILT_IN_VALUE_STREAM_DASHBOARD } from './constants';

/**
 * Fetches and returns the parsed YAML config file.
 *
 * @param {Number} projectId - ID of the project that contains the YAML config file
 * @returns {Object} The parsed YAML config file
 */
export const fetchYamlConfig = async (projectId) => {
  if (!projectId) return null;

  try {
    const { data } = await Api.getRawFile(projectId, YAML_CONFIG_PATH);
    return parse(data);
  } catch {
    return null;
  }
};

const snakeizeDoraVisualizationName = (name) => {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  return convertToSnakeCase(name.replace('DORA', 'Dora'));
};

/**
 * Searches the list of visualizations for the matching visualization and returns
 * the configuration if it exists.
 *
 * @param {Array} availableVisualizations - Array of currently available visualization configurations
 * @param {String} visualization - Name of the visualization to search for
 * @returns {Object} The visualization configuration object
 */
const extractAvailableVisualization = (availableVisualizations, visualization) => {
  const visualizationId = convertToSnakeCase(visualization);
  return availableVisualizations.find(({ type }) => {
    const snakeizedType = snakeizeDoraVisualizationName(type);
    return visualizationId === snakeizedType;
  });
};

/**
 * Prepares a raw dashboard configuration for rendering.
 *
 * Replaces the visualization name in the dashboard configuration
 * with the relevant visualization object.
 *
 * @param {Object} dashboard - ID of the project that contains the YAML config file
 * @param {Array} availableVisualizations - Array of currently available visualization configurations
 * @returns {Object} The parsed YAML config file with visualization definitions
 */
const prepareDashboard = (dashboard = null, availableVisualizations) => {
  if (!dashboard?.panels) {
    return null;
  }

  const { panels } = dashboard;
  return {
    ...dashboard,
    slug: BUILT_IN_VALUE_STREAM_DASHBOARD,
    panels: panels.map(({ visualization, ...panelsRest }) => ({
      ...panelsRest,
      visualization: extractAvailableVisualization(availableVisualizations, visualization),
    })),
  };
};

/**
 * Fetches a parsed YAML file and prepares the dashboard configuration
 * for rendering as a customizable dashboard
 *
 * @param {Number} projectId - ID of the project that contains the YAML config file
 * @param {Array} availableVisualizations - Array of currently available visualization configurations
 * @returns {Object} The parsed YAML config file
 */
export const hydrateLegacyYamlConfiguration = async (projectId, availableVisualizations = []) => {
  let customDashboardsProjectConfiguration;
  try {
    customDashboardsProjectConfiguration = await fetchYamlConfig(projectId);
  } catch (e) {
    return null;
  }
  return prepareDashboard(customDashboardsProjectConfiguration, availableVisualizations);
};

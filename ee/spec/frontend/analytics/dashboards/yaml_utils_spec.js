import { stringify } from 'yaml';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  hydrateLegacyYamlConfiguration,
  fetchYamlConfig,
} from 'ee/analytics/dashboards/yaml_utils';

let mock;

const YAML_PROJECT_ID = 1337;
const API_PATH = /\/api\/(.*)\/projects\/(.*)\/repository\/files\/\.gitlab%2Fanalytics%2Fdashboards%2Fvalue_streams%2Fvalue_streams\.ya?ml\/raw/;
const mockConfig = {
  title: 'TITLE',
  description: 'DESC',
  panels: [
    { data: { namespace: 'test/one' }, visualization: 'DoraChart' },
    { data: { namespace: 'test/two' }, visualization: 'DoraChart' },
  ],
};

describe('fetchYamlConfig', () => {
  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  it('returns null if the project ID is falsey', async () => {
    const config = await fetchYamlConfig(null);
    expect(config).toBeNull();
  });

  it('returns null if the file fails to load', async () => {
    mock.onGet(API_PATH).reply(HTTP_STATUS_NOT_FOUND);
    const config = await fetchYamlConfig(YAML_PROJECT_ID);
    expect(config).toBeNull();
  });

  it('returns null if the YAML config fails to parse', async () => {
    mock.onGet(API_PATH).reply(HTTP_STATUS_OK, { data: null });
    const config = await fetchYamlConfig(YAML_PROJECT_ID);
    expect(config).toBeNull();
  });

  it('returns the parsed YAML config on success', async () => {
    mock.onGet(API_PATH).reply(HTTP_STATUS_OK, stringify(mockConfig));
    const config = await fetchYamlConfig(YAML_PROJECT_ID);
    expect(config).toEqual(mockConfig);
  });
});

describe('hydrateLegacyYamlConfiguration', () => {
  let res;

  const availableVisualizations = [{ type: 'dora_chart' }];

  const preparedPanels = [
    { data: { namespace: 'test/one' }, visualization: { type: 'dora_chart' } },
    { data: { namespace: 'test/two' }, visualization: { type: 'dora_chart' } },
  ];

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(API_PATH).reply(HTTP_STATUS_OK, stringify(mockConfig));
  });

  describe('with available visualizations', () => {
    beforeEach(async () => {
      res = await hydrateLegacyYamlConfiguration(YAML_PROJECT_ID, availableVisualizations);
    });

    it('will populate the visualization definition', () => {
      expect(res.panels).toEqual(preparedPanels);
    });
  });

  describe('without a valid dashboard', () => {
    beforeEach(async () => {
      res = await hydrateLegacyYamlConfiguration(null, []);
    });

    it('will return null', () => {
      expect(res).toBe(null);
    });
  });

  describe('with no available visualizations', () => {
    beforeEach(async () => {
      res = await hydrateLegacyYamlConfiguration(YAML_PROJECT_ID, []);
    });

    it('will not populate the visualization definition', () => {
      res.panels.forEach((panel) => {
        expect(panel.visualization).toBeUndefined();
      });
    });
  });
});

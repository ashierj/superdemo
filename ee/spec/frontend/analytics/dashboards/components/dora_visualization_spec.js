import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { METRICS_WITHOUT_LABEL_FILTERING } from 'ee/analytics/dashboards/constants';
import DoraVisualization from 'ee/analytics/dashboards/components/dora_visualization.vue';
import ComparisonChartLabels from 'ee/analytics/dashboards/components/comparison_chart_labels.vue';
import ComparisonChart from 'ee/analytics/dashboards/components/comparison_chart.vue';
import GroupOrProjectProvider from 'ee/analytics/dashboards/components/group_or_project_provider.vue';
import GetGroupOrProjectQuery from 'ee/analytics/dashboards/graphql/get_group_or_project.query.graphql';
import filterLabelsQueryBuilder from 'ee/analytics/dashboards/graphql/filter_labels_query_builder';
import { mockGroup, mockProject } from '../mock_data';
import { mockFilterLabelsResponse } from '../helpers';

Vue.use(VueApollo);

describe('DoraVisualization', () => {
  let wrapper;

  const mockNamespaceProvider = (args = {}) => ({
    render() {
      return this.$scopedSlots.default({
        group: mockGroup,
        project: null,
        isProject: false,
        isNamespaceLoading: false,
        ...args,
      });
    },
  });

  const createWrapper = async ({
    props = {},
    filterLabelsResolver = null,
    groupOrProjectResolver = null,
    isProject = false,
    stubs = { GroupOrProjectProvider },
  } = {}) => {
    const filterLabels = props.data?.filter_labels || [];
    const apolloProvider = createMockApollo([
      [
        GetGroupOrProjectQuery,
        groupOrProjectResolver ||
          jest.fn().mockResolvedValueOnce({ data: { group: mockGroup, project: null } }),
      ],
      [
        filterLabelsQueryBuilder(filterLabels, isProject),
        filterLabelsResolver ||
          jest.fn().mockResolvedValue({ data: mockFilterLabelsResponse(filterLabels) }),
      ],
    ]);

    wrapper = shallowMountExtended(DoraVisualization, {
      apolloProvider,
      propsData: {
        fullPath: 'test/one',
        data: {},
        ...props,
      },
      stubs,
    });

    await waitForPromises();
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findNamespaceErrorAlert = () => wrapper.findByTestId('load-namespace-error');
  const findLabelsErrorAlert = () => wrapper.findByTestId('load-labels-error');
  const findComparisonChartLabels = () => wrapper.findComponent(ComparisonChartLabels);
  const findComparisonChartLabelTitles = () =>
    wrapper
      .findComponent(ComparisonChartLabels)
      .props('labels')
      .map(({ title }) => title);
  const findComparisonChart = () => wrapper.findComponent(ComparisonChart);
  const findTitle = () => wrapper.findByTestId('comparison-chart-title');

  it('shows a loading skeleton when fetching group/project details', () => {
    createWrapper({
      stubs: { GroupOrProjectProvider: mockNamespaceProvider({ isNamespaceLoading: true }) },
    });

    expect(findSkeletonLoader().exists()).toBe(true);
  });

  it('requests the namespace data', async () => {
    const handler = jest.fn().mockResolvedValueOnce();
    await createWrapper({
      groupOrProjectResolver: handler,
    });

    expect(handler).toHaveBeenCalledTimes(1);
  });

  it('shows an error alert if it failed to fetch group/project', async () => {
    await createWrapper({
      fullPath: 'test/one',
      groupOrProjectResolver: jest.fn().mockRejectedValueOnce(),
    });

    expect(findNamespaceErrorAlert().exists()).toBe(true);
    expect(findNamespaceErrorAlert().text()).toBe(
      'Failed to load comparison chart for Namespace: test/one',
    );
  });

  it('passes data attributes to the comparison chart', async () => {
    const fullPath = 'test';
    const excludeMetrics = ['one', 'two'];

    await createWrapper({ props: { fullPath, data: { exclude_metrics: excludeMetrics } } });
    expect(findComparisonChart().props()).toEqual(
      expect.objectContaining({ requestPath: fullPath, excludeMetrics }),
    );
  });

  it('renders a group with the default title', async () => {
    await createWrapper();

    expect(findTitle().text()).toEqual(`Metrics comparison for ${mockGroup.name} group`);
  });

  it('renders a project with the default title', async () => {
    await createWrapper({
      isProject: true,
      groupOrProjectResolver: jest
        .fn()
        .mockResolvedValueOnce({ data: { group: null, project: mockProject } }),
    });
    expect(findTitle().text()).toEqual(`Metrics comparison for ${mockProject.name} project`);
  });

  it('renders the custom title from the `title` prop', async () => {
    const title = 'custom title';

    await createWrapper({ props: { title } });
    expect(findTitle().text()).toEqual(title);
  });

  describe('filter_labels', () => {
    const fullPath = 'test';

    it('does not show labels when not defined', async () => {
      await createWrapper({ props: { fullPath } });
      expect(findComparisonChartLabels().exists()).toBe(false);
      expect(findComparisonChart().props('filterLabels')).toEqual([]);
    });

    it('does not show labels when empty', async () => {
      await createWrapper({ props: { fullPath, data: { filter_labels: [] } } });
      expect(findComparisonChartLabels().exists()).toBe(false);
      expect(findComparisonChart().props('filterLabels')).toEqual([]);
    });

    it('shows a loader when loading', async () => {
      const testLabels = ['testA', 'testB'];

      await createWrapper({
        props: { fullPath, data: { filter_labels: testLabels } },
        filterLabelsResolver: jest.fn().mockImplementation(() => new Promise(() => {})),
      });

      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findComparisonChart().exists()).toBe(false);
    });

    it('shows an error alert if it failed to fetch labels', async () => {
      const testLabels = ['testA', 'testB'];

      await createWrapper({
        props: { fullPath, data: { filter_labels: testLabels } },
        filterLabelsResolver: jest.fn().mockRejectedValue(),
      });

      expect(findComparisonChartLabels().exists()).toBe(false);
      expect(findComparisonChart().exists()).toBe(false);
      expect(findLabelsErrorAlert().exists()).toBe(true);
      expect(findLabelsErrorAlert().text()).toBe(
        'Failed to load labels matching the filter: testA, testB',
      );
    });

    it('removes duplicate labels from the result', async () => {
      const dupLabel = 'testA';
      const testLabels = [dupLabel, dupLabel, dupLabel];

      await createWrapper({
        props: { fullPath, data: { filter_labels: testLabels } },
      });

      expect(findComparisonChartLabels().exists()).toBe(true);
      expect(findComparisonChartLabelTitles()).toEqual([dupLabel]);
      expect(findComparisonChartLabels().props('webUrl')).toEqual(mockGroup.webUrl);
      expect(findComparisonChart().props('filterLabels')).toEqual([dupLabel]);
    });

    it('in addition to `exclude_metrics`, will exclude incompatible metrics', async () => {
      const testLabels = ['testA'];
      const excludeMetrics = ['cycle_time'];

      await createWrapper({
        props: { fullPath, data: { filter_labels: testLabels, exclude_metrics: excludeMetrics } },
      });

      expect(findComparisonChart().props()).toEqual(
        expect.objectContaining({
          filterLabels: testLabels,
          excludeMetrics: [...excludeMetrics, ...METRICS_WITHOUT_LABEL_FILTERING],
        }),
      );
    });
  });

  describe('comparison chart errors', () => {
    const errors = ['one', 'two'];

    beforeEach(async () => {
      await createWrapper();
      findComparisonChart().vm.$emit('set-errors', { errors });
    });

    it('renders an error alert', () => {
      const errorAlert = wrapper.findByTestId('comparison-chart-errors');

      expect(errorAlert.props().title).toBe('Failed to fetch data');
      errors.forEach((error) => expect(errorAlert.text()).toContain(error));
    });
  });
});

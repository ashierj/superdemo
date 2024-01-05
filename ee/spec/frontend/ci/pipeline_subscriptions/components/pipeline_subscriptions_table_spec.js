import { GlTable, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PipelineSubscriptionsTable from 'ee/ci/pipeline_subscriptions/components/pipeline_subscriptions_table.vue';
import { mockUpstreamSubscriptions } from '../mock_data';

describe('Pipeline Subscriptions Table', () => {
  let wrapper;

  const { count, nodes } = mockUpstreamSubscriptions.data.project.ciSubscriptionsProjects;

  const subscriptions = nodes.map((subscription) => {
    return {
      project: subscription.upstreamProject,
    };
  });

  const defaultProps = {
    count,
    subscriptions,
    emptyText: 'Empty',
    showActions: true,
    title: 'Subscriptions',
  };

  const findDeleteBtn = () => wrapper.findByTestId('delete-subscription-btn');
  const findAddNewBtn = () => wrapper.findByTestId('add-new-subscription-btn');
  const findTitle = () => wrapper.findByTestId('subscription-title');
  const findCount = () => wrapper.findByTestId('subscription-count');
  const findNamespace = () => wrapper.findByTestId('subscription-namespace');
  const findProject = () => wrapper.findComponent(GlLink);
  const findTable = () => wrapper.findComponent(GlTable);

  const createComponent = (props = defaultProps) => {
    wrapper = mountExtended(PipelineSubscriptionsTable, {
      propsData: {
        ...props,
      },
    });
  };

  it('displays title', () => {
    createComponent();

    expect(findTitle().text()).toBe(defaultProps.title);
  });

  it('displays count', () => {
    createComponent();

    expect(findCount().text()).toBe(String(defaultProps.count));
  });

  it('displays table', () => {
    createComponent();

    expect(findTable().exists()).toBe(true);
  });

  it('displays namespace', () => {
    createComponent();

    expect(findNamespace().text()).toBe(defaultProps.subscriptions[0].project.namespace.name);
  });

  it('displays project with link', () => {
    createComponent();

    expect(findProject().text()).toBe(defaultProps.subscriptions[0].project.name);
    expect(findProject().attributes('href')).toBe(defaultProps.subscriptions[0].project.webUrl);
  });

  it.each`
    visible  | showActions
    ${true}  | ${true}
    ${false} | ${false}
  `(
    'should display actions: $visible when showActions prop is: $showActions',
    ({ visible, showActions }) => {
      createComponent({ ...defaultProps, showActions });

      expect(findDeleteBtn().exists()).toBe(visible);
      expect(findAddNewBtn().exists()).toBe(visible);
    },
  );
});

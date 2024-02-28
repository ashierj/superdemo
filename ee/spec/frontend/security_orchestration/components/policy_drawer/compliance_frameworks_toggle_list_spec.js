import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLabel, GlLoadingIcon } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ComplianceFrameworksToggleList from 'ee/security_orchestration/components/policy_drawer/compliance_frameworks_toggle_list.vue';
import { complianceFrameworksResponse as defaultNodes } from 'ee_jest/security_orchestration/mocks/mock_apollo';
import getComplianceFrameworksQuery from 'ee/security_orchestration/graphql/queries/get_compliance_framework.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';

describe('ComplianceFrameworksToggleList', () => {
  let wrapper;
  let requestHandlers;

  const mockApolloHandlers = (nodes = defaultNodes) => {
    return {
      complianceFrameworks: jest.fn().mockResolvedValue({
        data: {
          namespace: {
            id: 1,
            name: 'name',
            complianceFrameworks: {
              nodes,
            },
          },
        },
      }),
    };
  };

  const createMockApolloProvider = (handlers) => {
    Vue.use(VueApollo);

    requestHandlers = handlers;
    return createMockApollo([[getComplianceFrameworksQuery, requestHandlers.complianceFrameworks]]);
  };

  const createComponent = ({ propsData = {}, handlers = mockApolloHandlers() } = {}) => {
    wrapper = shallowMountExtended(ComplianceFrameworksToggleList, {
      apolloProvider: createMockApolloProvider(handlers),
      provide: {
        rootNamespacePath: 'gitlab-org',
      },
      propsData: {
        complianceFrameworkIds: [],
        ...propsData,
      },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAllLabels = () => wrapper.findAllComponents(GlLabel);
  const findHeader = () => wrapper.findByTestId('compliance-frameworks-header');
  const findHiddenLabelText = () => wrapper.findByTestId('hidden-labels-text');

  describe('all frameworks', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should render loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findAllLabels().exists()).toBe(false);
    });

    it('should fetch all frameworks', () => {
      expect(requestHandlers.complianceFrameworks).toHaveBeenCalledWith({
        complianceFrameworkIds: [],
        fullPath: 'gitlab-org',
      });
    });

    it('renders compliance frameworks', async () => {
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findAllLabels().exists()).toBe(true);

      expect(findAllLabels()).toHaveLength(defaultNodes.length);
    });

    it('renders header for all compliance frameworks', async () => {
      await waitForPromises();

      expect(findHeader().text()).toBe('2 projects which have compliance framework:');
    });
  });

  describe('single framework', () => {
    beforeEach(() => {
      createComponent({
        handlers: mockApolloHandlers([defaultNodes[1]]),
      });
    });

    it('renders header for single compliance frameworks', async () => {
      await waitForPromises();

      expect(findHeader().text()).toBe('1 project which has compliance framework:');
    });
  });

  describe('selected compliance framework', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          complianceFrameworkIds: [defaultNodes[0].id],
        },
        handlers: mockApolloHandlers([defaultNodes[0]]),
      });
    });

    it('fetches selected compliance framework', () => {
      expect(requestHandlers.complianceFrameworks).toHaveBeenCalledWith({
        complianceFrameworkIds: ['gid://gitlab/ComplianceManagement::Framework/1'],
        fullPath: 'gitlab-org',
      });
    });

    it('renders labels for selected components', async () => {
      await waitForPromises();

      expect(findAllLabels()).toHaveLength(1);
    });

    it('renders header for selected compliance frameworks', async () => {
      await waitForPromises();

      expect(findHeader().text()).toBe('This applies to following compliance frameworks:');
    });
  });

  describe('error state', () => {
    beforeEach(() => {
      createComponent({
        handlers: {
          complianceFrameworks: jest.fn().mockRejectedValue({}),
        },
      });
    });

    it('emits error when query is failing', async () => {
      await waitForPromises();
      expect(wrapper.emitted('framework-query-error')).toHaveLength(1);
    });
  });

  describe('partial rendered list', () => {
    const { length: DEFAULT_NODES_LENGTH } = defaultNodes;

    it.each`
      labelsToShow | expectedLength | expectedText
      ${2}         | ${2}           | ${'+ 1 more'}
      ${1}         | ${1}           | ${'+ 2 more'}
    `('can show only partial list', async ({ labelsToShow, expectedLength, expectedText }) => {
      createComponent({
        propsData: {
          labelsToShow,
        },
      });
      await waitForPromises();

      expect(findAllLabels()).toHaveLength(expectedLength);
      expect(findHiddenLabelText().text()).toBe(expectedText);
    });

    it.each`
      labelsToShow           | expectedLength          | hiddenTextExist
      ${10}                  | ${DEFAULT_NODES_LENGTH} | ${false}
      ${undefined}           | ${DEFAULT_NODES_LENGTH} | ${false}
      ${NaN}                 | ${DEFAULT_NODES_LENGTH} | ${false}
      ${null}                | ${DEFAULT_NODES_LENGTH} | ${false}
      ${2}                   | ${2}                    | ${true}
      ${defaultNodes.length} | ${DEFAULT_NODES_LENGTH} | ${false}
    `(
      'shows full list if labelsToShow is more than total number of labels',
      async ({ labelsToShow, expectedLength, hiddenTextExist }) => {
        createComponent({
          propsData: {
            labelsToShow,
          },
        });
        await waitForPromises();

        expect(findAllLabels()).toHaveLength(expectedLength);
        expect(findHiddenLabelText().exists()).toBe(hiddenTextExist);
      },
    );
  });

  describe('custom header', () => {
    it('renders custom header message', async () => {
      createComponent({
        propsData: {
          customHeaderMessage: 'Test header',
        },
      });

      await waitForPromises();

      expect(findHeader().text()).toBe('Test header');
    });
  });
});

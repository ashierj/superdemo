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

      expect(findHeader().text()).toBe(
        'This applies to 2 projects associated with following compliance frameworks:',
      );
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
});

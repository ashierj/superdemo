import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlButton, GlCollapsibleListbox, GlModal } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import ComplianceFrameworkDropdown from 'ee/security_orchestration/components/policy_editor/scope/compliance_framework_dropdown.vue';
import ComplianceFrameworkFormModal from 'ee/groups/settings/compliance_frameworks/components/form_modal.vue';
import CreateForm from 'ee/groups/settings/compliance_frameworks/components/create_form.vue';
import SharedForm from 'ee/groups/settings/compliance_frameworks/components/shared_form.vue';
import getComplianceFrameworkQuery from 'ee/graphql_shared/queries/get_compliance_framework.query.graphql';
import createComplianceFrameworkMutation from 'ee/groups/settings/compliance_frameworks/graphql/queries/create_compliance_framework.mutation.graphql';
import { validCreateResponse } from 'ee_jest/groups/settings/compliance_frameworks/mock_data';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';

describe('ComplianceFrameworkDropdown', () => {
  let wrapper;
  let requestHandlers;

  const showMock = jest.fn();
  const hideMock = jest.fn();

  const defaultNodes = [
    {
      id: 1,
      name: 'A1',
      default: true,
      description: 'description 1',
      color: 'color 1',
      pipelineConfigurationFullPath: 'path 1',
    },
    {
      id: 2,
      name: 'B2',
      default: false,
      description: 'description 2',
      color: 'color 2',
      pipelineConfigurationFullPath: 'path 2',
    },
    {
      id: 3,
      name: 'a3',
      default: true,
      description: 'description 3',
      color: 'color 3',
      pipelineConfigurationFullPath: 'path 3',
    },
  ];

  const defaultNodesIds = defaultNodes.map(({ id }) => id);

  const mapItems = (items) =>
    items.map(({ id, name, ...framework }) => ({ value: id, text: name, ...framework }));

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
      createFrameworkHandler: jest.fn().mockResolvedValue(validCreateResponse),
    };
  };

  const createMockApolloProvider = (handlers) => {
    Vue.use(VueApollo);

    requestHandlers = handlers;
    return createMockApollo([
      [getComplianceFrameworkQuery, requestHandlers.complianceFrameworks],
      [createComplianceFrameworkMutation, requestHandlers.createFrameworkHandler],
    ]);
  };

  const createComponent = ({
    propsData = {},
    handlers = mockApolloHandlers(),
    stubs = {},
  } = {}) => {
    wrapper = shallowMount(ComplianceFrameworkDropdown, {
      apolloProvider: createMockApolloProvider(handlers),
      propsData: {
        fullPath: 'gitlab-org',
        ...propsData,
      },
      stubs: {
        ComplianceFrameworkFormModal,
        GlModal: stubComponent(GlModal, {
          methods: {
            show: showMock,
            hide: hideMock,
          },
        }),
        ...stubs,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findCreateFrameworkButton = () => wrapper.findComponent(GlButton);
  const findComplianceFrameworkFormModal = () =>
    wrapper.findComponent(ComplianceFrameworkFormModal);
  const findSharedForm = () => wrapper.findComponent(SharedForm);
  const selectAll = () => findDropdown().vm.$emit('select-all');
  const resetAll = () => findDropdown().vm.$emit('reset');

  describe('without selected frameworks', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should render loading state', () => {
      expect(findDropdown().props('loading')).toBe(true);
    });

    it('should load compliance framework', async () => {
      await waitForPromises();
      expect(findDropdown().props('loading')).toBe(false);
      expect(findDropdown().props('items')).toEqual(mapItems(defaultNodes));
    });

    it('should select framework ids', async () => {
      const [{ id }] = defaultNodes;

      await waitForPromises();
      findDropdown().vm.$emit('select', id);
      expect(wrapper.emitted('select')).toEqual([[id]]);
    });

    it('should select all frameworks', async () => {
      await waitForPromises();
      selectAll();
      expect(wrapper.emitted('select')).toEqual([[defaultNodesIds]]);
    });

    it('renders default text when loading', () => {
      expect(findDropdown().props('toggleText')).toBe('Choose framework labels');
    });

    it('should search frameworks despite case', async () => {
      await waitForPromises();

      expect(findDropdown().props('items')).toHaveLength(3);

      await findDropdown().vm.$emit('search', 'a');
      expect(findDropdown().props('items')).toEqual(mapItems([defaultNodes[0], defaultNodes[2]]));
      expect(findDropdown().props('items')).toHaveLength(2);
    });

    it('should render framework create form', () => {
      findCreateFrameworkButton().vm.$emit('click');

      expect(showMock).toHaveBeenCalled();
      findComplianceFrameworkFormModal().vm.$emit('change');

      expect(hideMock).toHaveBeenCalled();
    });
  });

  describe('create new framework', () => {
    it('re-fetches compliance frameworks when a new one is created', async () => {
      createComponent({
        stubs: {
          CreateForm,
        },
      });
      expect(requestHandlers.complianceFrameworks).toHaveBeenCalledTimes(1);
      findCreateFrameworkButton().vm.$emit('click');
      findSharedForm().vm.$emit('submit');

      await waitForPromises();

      expect(showMock).toHaveBeenCalled();
      expect(requestHandlers.complianceFrameworks).toHaveBeenCalledTimes(2);
      expect(requestHandlers.complianceFrameworks).toHaveBeenNthCalledWith(2, {
        fullPath: 'gitlab-org',
      });
    });
  });

  describe('compliance framework list is empty', () => {
    it('renders default text when no frameworks were fetched', async () => {
      createComponent({
        handlers: mockApolloHandlers([]),
      });
      await waitForPromises();
      expect(findDropdown().props('toggleText')).toBe('Choose framework labels');
    });
  });

  describe('selected frameworks', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          selectedFrameworkIds: defaultNodesIds,
        },
      });
    });

    it('should be possible to preselect frameworks', async () => {
      await waitForPromises();
      expect(findDropdown().props('selected')).toEqual(defaultNodesIds);
    });

    it('renders all frameworks selected text', async () => {
      await waitForPromises();
      expect(findDropdown().props('toggleText')).toBe('All frameworks selected');
    });

    it('should reset all frameworks', async () => {
      await waitForPromises();
      resetAll();

      expect(wrapper.emitted('select')).toEqual([[[]]]);
    });
  });

  describe('one selected project', () => {
    it('should render text for selected framework', async () => {
      createComponent({
        propsData: {
          selectedFrameworkIds: [defaultNodesIds[0]],
        },
      });

      await waitForPromises();
      expect(findDropdown().props('toggleText')).toBe('1 compliance framework selected');
    });
  });

  describe('when the fetch query throws an error', () => {
    it('emits an error event', async () => {
      createComponent({
        handlers: {
          complianceFrameworks: jest.fn().mockRejectedValue({}),
        },
      });
      await waitForPromises();
      expect(wrapper.emitted('framework-query-error')).toHaveLength(1);
    });
  });
});

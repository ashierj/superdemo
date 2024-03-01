import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import WorkItemProgressInline from 'ee/work_items/components/work_item_progress_inline.vue';
import WorkItemProgressWithEdit from 'ee/work_items/components/work_item_progress_with_edit.vue';
import WorkItemHealthStatus from 'ee/work_items/components/work_item_health_status_with_edit.vue';
import WorkItemHealthStatusInline from 'ee/work_items/components/work_item_health_status_inline.vue';
import WorkItemWeight from 'ee/work_items/components/work_item_weight_with_edit.vue';
import WorkItemWeightInline from 'ee/work_items/components/work_item_weight_inline.vue';
import WorkItemIterationInline from 'ee/work_items/components/work_item_iteration_inline.vue';
import WorkItemColorInline from 'ee/work_items/components/work_item_color_inline.vue';
import WorkItemColorWithEdit from 'ee/work_items/components/work_item_color_with_edit.vue';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { workItemResponseFactory } from 'jest/work_items/mock_data';

import WorkItemAttributesWrapper from '~/work_items/components/work_item_attributes_wrapper.vue';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemUpdatedSubscription from '~/work_items/graphql/work_item_updated.subscription.graphql';

describe('EE WorkItemAttributesWrapper component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const workItemQueryResponse = workItemResponseFactory({ canUpdate: true, canDelete: true });

  const successHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
  const workItemUpdatedSubscriptionHandler = jest
    .fn()
    .mockResolvedValue({ data: { workItemUpdated: null } });

  const findWorkItemIterationInline = () => wrapper.findComponent(WorkItemIterationInline);
  const findWorkItemWeight = () => wrapper.findComponent(WorkItemWeight);
  const findWorkItemWeightInline = () => wrapper.findComponent(WorkItemWeightInline);
  const findWorkItemProgressInline = () => wrapper.findComponent(WorkItemProgressInline);
  const findWorkItemProgressWithEdit = () => wrapper.findComponent(WorkItemProgressWithEdit);
  const findWorkItemColorInline = () => wrapper.findComponent(WorkItemColorInline);
  const findWorkItemColorWithEdit = () => wrapper.findComponent(WorkItemColorWithEdit);
  const findWorkItemHealthStatus = () => wrapper.findComponent(WorkItemHealthStatus);
  const findWorkItemHealthStatusInline = () => wrapper.findComponent(WorkItemHealthStatusInline);

  const createComponent = ({
    workItem = workItemQueryResponse.data.workItem,
    handler = successHandler,
    confidentialityMock = [updateWorkItemMutation, jest.fn()],
    workItemsBeta = true,
  } = {}) => {
    wrapper = shallowMount(WorkItemAttributesWrapper, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, handler],
        [workItemUpdatedSubscription, workItemUpdatedSubscriptionHandler],
        confidentialityMock,
      ]),
      propsData: {
        fullPath: 'group/project',
        workItem,
      },
      provide: {
        hasIssueWeightsFeature: true,
        hasIterationsFeature: true,
        hasOkrsFeature: true,
        hasIssuableHealthStatusFeature: true,
        projectNamespace: 'namespace',
        glFeatures: {
          workItemsBeta,
        },
      },
    });
  };

  describe('iteration widget', () => {
    describe.each`
      description                               | iterationWidgetPresent | exists
      ${'when widget is returned from API'}     | ${true}                | ${true}
      ${'when widget is not returned from API'} | ${false}               | ${false}
    `('$description', ({ iterationWidgetPresent, exists }) => {
      it(`${
        iterationWidgetPresent ? 'renders' : 'does not render'
      } iteration component`, async () => {
        const response = workItemResponseFactory({ iterationWidgetPresent });
        createComponent({ workItem: response.data.workItem, workItemsBeta: false });
        await waitForPromises();

        expect(findWorkItemIterationInline().exists()).toBe(exists);
      });
    });

    it('emits an error event to the wrapper', async () => {
      createComponent({ workItemsBeta: false });
      const updateError = 'Failed to update';

      findWorkItemIterationInline().vm.$emit('error', updateError);
      await nextTick();

      expect(wrapper.emitted('error')).toEqual([[updateError]]);
    });
  });

  describe('weight widget', () => {
    describe.each`
      description                               | weightWidgetPresent | exists
      ${'when widget is returned from API'}     | ${true}             | ${true}
      ${'when widget is not returned from API'} | ${false}            | ${false}
    `('$description', ({ weightWidgetPresent, exists }) => {
      it(`${weightWidgetPresent ? 'renders' : 'does not render'} weight component`, async () => {
        const response = workItemResponseFactory({ weightWidgetPresent });
        createComponent({ workItem: response.data.workItem });

        await waitForPromises();

        expect(findWorkItemWeight().exists()).toBe(exists);
      });
    });

    it('renders WorkItemWeight when workItemsBeta enabled', async () => {
      createComponent();

      await waitForPromises();

      expect(findWorkItemWeight().exists()).toBe(true);
      expect(findWorkItemWeightInline().exists()).toBe(false);
    });

    it('renders WorkItemWeightInline when workItemsBeta disabled', async () => {
      createComponent({ workItemsBeta: false });

      await waitForPromises();

      expect(findWorkItemWeight().exists()).toBe(false);
      expect(findWorkItemWeightInline().exists()).toBe(true);
    });

    it('emits an error event to the wrapper', async () => {
      const response = workItemResponseFactory({ weightWidgetPresent: true });
      createComponent({ workItem: response.data.workItem });
      const updateError = 'Failed to update';

      await waitForPromises();

      findWorkItemWeight().vm.$emit('error', updateError);
      await nextTick();

      expect(wrapper.emitted('error')).toEqual([[updateError]]);
    });
  });

  describe('health status widget', () => {
    describe.each`
      description                               | healthStatusWidgetPresent | exists
      ${'when widget is returned from API'}     | ${true}                   | ${true}
      ${'when widget is not returned from API'} | ${false}                  | ${false}
    `('$description', ({ healthStatusWidgetPresent, exists }) => {
      it(`${
        healthStatusWidgetPresent ? 'renders' : 'does not render'
      } healthStatus component`, () => {
        const response = workItemResponseFactory({ healthStatusWidgetPresent });
        createComponent({ workItem: response.data.workItem });

        expect(findWorkItemHealthStatus().exists()).toBe(exists);
      });
    });

    it('renders WorkItemHealthStatus when workItemsBeta enabled', async () => {
      createComponent();

      await waitForPromises();

      expect(findWorkItemHealthStatus().exists()).toBe(true);
      expect(findWorkItemHealthStatusInline().exists()).toBe(false);
    });

    it('renders WorkItemHealthStatusInline when workItemsBeta disabled', async () => {
      createComponent({ workItemsBeta: false });

      await waitForPromises();

      expect(findWorkItemHealthStatus().exists()).toBe(false);
      expect(findWorkItemHealthStatusInline().exists()).toBe(true);
    });

    it('emits an error event to the wrapper', async () => {
      const response = workItemResponseFactory({ healthStatusWidgetPresent: true });
      createComponent({ workItem: response.data.workItem });
      const updateError = 'Failed to update';

      findWorkItemHealthStatus().vm.$emit('error', updateError);
      await nextTick();

      expect(wrapper.emitted('error')).toEqual([[updateError]]);
    });
  });

  describe('progress widget', () => {
    describe.each`
      description                               | progressWidgetPresent | exists
      ${'when widget is returned from API'}     | ${true}               | ${true}
      ${'when widget is not returned from API'} | ${false}              | ${false}
    `('$description', ({ progressWidgetPresent, exists }) => {
      it(`${progressWidgetPresent ? 'renders' : 'does not render'} progress component`, () => {
        const response = workItemResponseFactory({ progressWidgetPresent });
        createComponent({ workItem: response.data.workItem });

        expect(findWorkItemProgressWithEdit().exists()).toBe(exists);
      });
    });

    it('renders WorkItemProgressWithEdit when workItemsBeta enabled', async () => {
      createComponent();

      await waitForPromises();

      expect(findWorkItemProgressWithEdit().exists()).toBe(true);
      expect(findWorkItemProgressInline().exists()).toBe(false);
    });

    it('renders WorkItemProgressInline when workItemsBeta disabled', async () => {
      createComponent({ workItemsBeta: false });

      await waitForPromises();

      expect(findWorkItemProgressWithEdit().exists()).toBe(false);
      expect(findWorkItemProgressInline().exists()).toBe(true);
    });

    it('emits an error event to the wrapper', async () => {
      const response = workItemResponseFactory({ progressWidgetPresent: true });
      createComponent({ workItem: response.data.workItem });
      const updateError = 'Failed to update';

      findWorkItemProgressWithEdit().vm.$emit('error', updateError);
      await nextTick();

      expect(wrapper.emitted('error')).toEqual([[updateError]]);
    });
  });

  describe('color widget', () => {
    describe.each`
      description                               | colorWidgetPresent | exists
      ${'when widget is returned from API'}     | ${true}            | ${true}
      ${'when widget is not returned from API'} | ${false}           | ${false}
    `('$description', ({ colorWidgetPresent, exists }) => {
      it(`${colorWidgetPresent ? 'renders' : 'does not render'} color component`, () => {
        const response = workItemResponseFactory({ colorWidgetPresent });

        createComponent({ workItem: response.data.workItem });

        expect(findWorkItemColorWithEdit().exists()).toBe(exists);
      });
    });

    it('renders WorkItemColorWithEdit when workItemsBeta enabled', async () => {
      createComponent();

      await waitForPromises();

      expect(findWorkItemColorWithEdit().exists()).toBe(true);
      expect(findWorkItemColorInline().exists()).toBe(false);
    });

    it('renders WorkItemColorInline when workItemsBeta disabled', async () => {
      createComponent({ workItemsBeta: false });

      await waitForPromises();

      expect(findWorkItemColorWithEdit().exists()).toBe(false);
      expect(findWorkItemColorInline().exists()).toBe(true);
    });

    it('emits an error event to the wrapper', async () => {
      const response = workItemResponseFactory({ colorWidgetPresent: true });
      createComponent({ workItem: response.data.workItem });
      const updateError = 'Failed to update';

      findWorkItemColorWithEdit().vm.$emit('error', updateError);
      await nextTick();

      expect(wrapper.emitted('error')).toEqual([[updateError]]);
    });
  });
});

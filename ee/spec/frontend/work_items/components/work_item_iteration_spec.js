import { GlCollapsibleListbox, GlFormGroup, GlListboxItem, GlSkeletonLoader } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import WorkItemIteration from 'ee/work_items/components/work_item_iteration.vue';
import projectIterationsQuery from 'ee/work_items/graphql/project_iterations.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  groupIterationsResponse,
  groupIterationsResponseWithNoIterations,
  mockIterationWidgetResponse,
  updateWorkItemMutationErrorResponse,
  updateWorkItemMutationResponse,
} from 'jest/work_items/mock_data';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';

describe('WorkItemIteration component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const workItemId = 'gid://gitlab/WorkItem/1';
  const workItemType = 'Task';

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findNoIterationDropdownItem = () => wrapper.findByText('No iteration');
  const findDropdownItems = () => wrapper.findAllComponents(GlListboxItem);
  const findDisabledTextSpan = () => wrapper.findByTestId('disabled-text');
  const findInputGroup = () => wrapper.findComponent(GlFormGroup);
  const findNoResultsText = () => wrapper.findByTestId('no-results-text');

  const successSearchQueryHandler = jest.fn().mockResolvedValue(groupIterationsResponse);
  const successSearchWithNoMatchingIterations = jest
    .fn()
    .mockResolvedValue(groupIterationsResponseWithNoIterations);
  const successUpdateWorkItemMutationHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemMutationResponse);

  const showDropdown = () => findDropdown().vm.$emit('shown');

  const createComponent = ({
    canUpdate = true,
    iteration = mockIterationWidgetResponse,
    workItemIid = '1',
    searchQueryHandler = successSearchQueryHandler,
    mutationHandler = successUpdateWorkItemMutationHandler,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemIteration, {
      apolloProvider: createMockApollo([
        [projectIterationsQuery, searchQueryHandler],
        [updateWorkItemMutation, mutationHandler],
      ]),
      propsData: {
        canUpdate,
        fullPath: 'test-project-path',
        iteration,
        workItemId,
        workItemIid,
        workItemType,
      },
      provide: {
        hasIterationsFeature: true,
      },
      stubs: {
        GlCollapsibleListbox,
      },
    });
  };

  it('has "Iteration" label', () => {
    createComponent();

    expect(findInputGroup().attributes('label')).toBe('Iteration');
  });

  describe('Default text with canUpdate false and iteration value', () => {
    describe.each`
      description             | iteration                      | value
      ${'when no iteration'}  | ${null}                        | ${'None'}
      ${'when iteration set'} | ${mockIterationWidgetResponse} | ${mockIterationWidgetResponse.title}
    `('$description', ({ iteration, value }) => {
      it(`has a value of "${value}"`, () => {
        createComponent({ canUpdate: false, iteration });

        expect(findDisabledTextSpan().text()).toBe(value);
        expect(findDropdown().exists()).toBe(false);
      });
    });
  });

  describe('Default text value when canUpdate true and no iteration set', () => {
    it(`has a value of "Add to iteration"`, () => {
      createComponent({ canUpdate: true, iteration: null });

      expect(findDropdown().props('toggleText')).toBe('Add to iteration');
    });
  });

  describe('Dropdown search', () => {
    it('has the search box', () => {
      createComponent();

      expect(findDropdown().props('searchable')).toBe(true);
    });

    it('shows no matching results when no items', () => {
      createComponent({ searchQueryHandler: successSearchWithNoMatchingIterations });

      expect(findNoResultsText().text()).toBe('No matching results');
      expect(findDropdownItems()).toHaveLength(1);
    });
  });

  describe('Dropdown options', () => {
    beforeEach(() => {
      createComponent({ canUpdate: true });
    });

    it('calls successSearchQueryHandler with variables when dropdown is opened', async () => {
      showDropdown();
      await nextTick();

      expect(successSearchQueryHandler).toHaveBeenCalledWith({
        fullPath: 'test-project-path',
        state: 'opened',
        title: '',
      });
    });

    it('shows the skeleton loader when the items are being fetched on click', async () => {
      showDropdown();
      await nextTick();

      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('shows the iterations in dropdown when the items have finished fetching', async () => {
      showDropdown();
      await waitForPromises();

      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findNoIterationDropdownItem().exists()).toBe(true);
      expect(findDropdownItems()).toHaveLength(
        groupIterationsResponse.data.workspace.attributes.nodes.length + 1,
      );
    });

    it('changes the iteration to null when clicked on no iteration', async () => {
      findDropdown().vm.$emit('select', 'no-iteration-id');
      await nextTick();

      expect(findDropdown().props('loading')).toBe(true);

      await waitForPromises();

      expect(findDropdown().props()).toMatchObject({
        loading: false,
        toggleText: 'Iteration title widget',
      });
    });

    it('changes the iteration to the selected iteration', async () => {
      const iterationIndex = 1;
      /** the index is -1 since no matching results is also a dropdown item */
      const iterationAtIndex =
        groupIterationsResponse.data.workspace.attributes.nodes[iterationIndex - 1];

      findDropdown().vm.$emit('select', iterationAtIndex.id);
      await waitForPromises();

      expect(findDropdown().props('toggleText')).toBe('Iteration title widget');
    });
  });

  describe('Error handlers', () => {
    it.each`
      errorType          | expectedErrorMessage                                                 | mockValue                              | resolveFunction
      ${'graphql error'} | ${'Something went wrong while updating the task. Please try again.'} | ${updateWorkItemMutationErrorResponse} | ${'mockResolvedValue'}
      ${'network error'} | ${'Something went wrong while updating the task. Please try again.'} | ${new Error()}                         | ${'mockRejectedValue'}
    `(
      'emits an error when there is a $errorType',
      async ({ mockValue, expectedErrorMessage, resolveFunction }) => {
        createComponent({
          mutationHandler: jest.fn()[resolveFunction](mockValue),
          canUpdate: true,
        });

        findDropdown().vm.$emit('select', 'no-iteration-id');
        await waitForPromises();

        expect(wrapper.emitted('error')).toEqual([[expectedErrorMessage]]);
      },
    );
  });

  describe('Tracking event', () => {
    it('tracks updating the iteration', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      createComponent({ canUpdate: true });

      findDropdown().vm.$emit('select', 'no-iteration-id');
      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'updated_iteration', {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_iteration',
        property: 'type_Task',
      });
    });
  });
});

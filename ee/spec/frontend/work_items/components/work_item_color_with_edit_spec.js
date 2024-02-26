import { GlDisclosureDropdown } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  updateWorkItemMutationResponseFactory,
  groupWorkItemByIidResponseFactory,
  updateWorkItemMutationErrorResponse,
  epicType,
} from 'jest/work_items/mock_data';
import WorkItemColorWithEdit from 'ee/work_items/components/work_item_color_with_edit.vue';
import SidebarColorView from '~/sidebar/components/sidebar_color_view.vue';
import SidebarColorPicker from '~/sidebar/components/sidebar_color_picker.vue';
import { DEFAULT_COLOR } from '~/vue_shared/components/color_select_dropdown/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { workItemColorWidget } from '../mock_data';

describe('WorkItemColor component', () => {
  Vue.use(VueApollo);

  let wrapper;
  const selectedColor = '#ffffff';

  const mockWorkItem = groupWorkItemByIidResponseFactory({
    workItemType: epicType,
    colorWidgetPresent: true,
    color: DEFAULT_COLOR.color,
  }).data.workspace.workItems.nodes[0];
  const mockSelectedColorWorkItem = groupWorkItemByIidResponseFactory({
    workItemType: epicType,
    colorWidgetPresent: true,
    color: selectedColor,
  }).data.workspace.workItems.nodes[0];
  const successUpdateWorkItemMutationHandler = jest
    .fn()
    .mockResolvedValue(
      updateWorkItemMutationResponseFactory({ colorWidgetPresent: true, color: selectedColor }),
    );
  const successUpdateWorkItemMutationDefaultColorHandler = jest.fn().mockResolvedValue(
    updateWorkItemMutationResponseFactory({
      colorWidgetPresent: true,
      color: DEFAULT_COLOR.color,
    }),
  );

  const createComponent = ({
    canUpdate = true,
    mutationHandler = successUpdateWorkItemMutationHandler,
    workItem = mockWorkItem,
    mountFn = shallowMountExtended,
    stubs = {},
  } = {}) => {
    wrapper = mountFn(WorkItemColorWithEdit, {
      apolloProvider: createMockApollo([[updateWorkItemMutation, mutationHandler]]),
      propsData: {
        canUpdate,
        workItem,
      },
      stubs,
    });
  };

  const findSidebarColorView = () => wrapper.findComponent(SidebarColorView);
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findSidebarColorPicker = () => wrapper.findComponent(SidebarColorPicker);
  const findColorHeaderTitle = () => wrapper.findByTestId('color-header-title');
  const findEditButton = () => wrapper.findByTestId('edit-color');
  const findApplyButton = () => wrapper.findByTestId('apply-color');

  const selectColor = async (color) => {
    await findEditButton().vm.$emit('click');
    findSidebarColorPicker().vm.$emit('input', color);
    findDropdown().vm.$emit('hidden');
  };

  describe('when work item epic color can not be updated', () => {
    beforeEach(() => {
      createComponent({ canUpdate: false, workItem: mockSelectedColorWorkItem });
    });

    it('renders the color view component with provided value', () => {
      expect(findSidebarColorView().exists()).toBe(true);
      expect(findSidebarColorView().props('color')).toBe(selectedColor);
    });

    it('does not render the color picker component and edit button', () => {
      expect(findSidebarColorPicker().exists()).toBe(false);
      expect(findEditButton().exists()).toBe(false);
    });
  });

  describe('when work item epic color can be updated', () => {
    describe('when not editing', () => {
      beforeEach(() => {
        createComponent({ workItem: mockSelectedColorWorkItem });
      });

      it('renders the color view component and the edit button', () => {
        expect(findSidebarColorView().exists()).toBe(true);
        expect(findSidebarColorView().props('color')).toBe(selectedColor);
        expect(findEditButton().exists()).toBe(true);
      });

      it('does not render the color picker component', () => {
        expect(findSidebarColorPicker().exists()).toBe(false);
      });
    });

    describe('when editing', () => {
      beforeEach(() => {
        createComponent({ workItem: mockWorkItem });
        findEditButton().vm.$emit('click');
      });

      it('renders the color picker component and the apply button', () => {
        expect(findSidebarColorPicker().exists()).toBe(true);
        expect(findApplyButton().exists()).toBe(true);
      });

      it('does not render the color view component and edit button', () => {
        expect(findSidebarColorView().exists()).toBe(false);
        expect(findEditButton().exists()).toBe(false);
      });

      it('updates the color if apply button is clicked after selecting input color', async () => {
        findSidebarColorPicker().vm.$emit('input', selectedColor);
        findApplyButton().vm.$emit('click');

        await waitForPromises();

        expect(successUpdateWorkItemMutationHandler).toHaveBeenCalledWith({
          input: {
            id: workItemColorWidget.id,
            colorWidget: {
              color: selectedColor,
            },
          },
        });
      });

      it.each`
        color                  | inputColor       | successHandler
        ${selectedColor}       | ${selectedColor} | ${successUpdateWorkItemMutationHandler}
        ${DEFAULT_COLOR.color} | ${null}          | ${successUpdateWorkItemMutationDefaultColorHandler}
      `(
        'updates the color from $inputColor to $color if dropdown is closed after selecting input color',
        async ({ color, inputColor, successHandler }) => {
          createComponent({ mutationHandler: successHandler });

          selectColor(inputColor);

          await waitForPromises();

          expect(successHandler).toHaveBeenCalledWith({
            input: {
              id: workItemColorWidget.id,
              colorWidget: {
                color,
              },
            },
          });
        },
      );

      it.each`
        errorType          | expectedErrorMessage                                                 | failureHandler
        ${'graphql error'} | ${'Something went wrong while updating the epic. Please try again.'} | ${jest.fn().mockResolvedValue(updateWorkItemMutationErrorResponse)}
        ${'network error'} | ${'Something went wrong while updating the epic. Please try again.'} | ${jest.fn().mockRejectedValue(new Error())}
      `(
        'emits an error when there is a $errorType',
        async ({ expectedErrorMessage, failureHandler }) => {
          createComponent({
            mutationHandler: failureHandler,
          });

          selectColor(selectedColor);

          await waitForPromises();

          expect(wrapper.emitted('error')).toEqual([[expectedErrorMessage]]);
        },
      );
    });
  });

  it('renders the title in the dropdown header', async () => {
    createComponent({ mountFn: mountExtended, stubs: { SidebarColorPicker: true } });

    await findEditButton().vm.$emit('click');

    expect(findColorHeaderTitle().text()).toBe('Select a color');
  });
});

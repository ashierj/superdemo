import { GlDisclosureDropdown, GlFormGroup } from '@gitlab/ui';
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
import WorkItemColorInline from 'ee/work_items/components/work_item_color_inline.vue';
import SidebarColorView from '~/sidebar/components/sidebar_color_view.vue';
import SidebarColorPicker from '~/sidebar/components/sidebar_color_picker.vue';
import { DEFAULT_COLOR } from '~/vue_shared/components/color_select_dropdown/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { workItemColorWidget } from '../mock_data';

describe('WorkItemColorInline', () => {
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
    wrapper = mountFn(WorkItemColorInline, {
      apolloProvider: createMockApollo([[updateWorkItemMutation, mutationHandler]]),
      propsData: {
        canUpdate,
        workItem,
      },
      stubs,
    });
  };

  const findGlFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findSidebarColorView = () => wrapper.findComponent(SidebarColorView);
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findSidebarColorPicker = () => wrapper.findComponent(SidebarColorPicker);
  const findColorHeaderTitle = () => wrapper.findByTestId('color-header-title');

  const selectColor = (color) => {
    findSidebarColorPicker().vm.$emit('input', color);
    findDropdown().vm.$emit('hidden');
  };

  it('renders the color view component and not the color picker', () => {
    createComponent({ workItem: mockSelectedColorWorkItem, canUpdate: false });

    expect(findSidebarColorView().props('color')).toBe(selectedColor);
    expect(findSidebarColorPicker().exists()).toBe(false);
  });

  it('renders the header title in the dropdown', () => {
    createComponent({ mountFn: mountExtended, stubs: { SidebarColorPicker: true } });

    expect(findColorHeaderTitle().text()).toBe('Select a color');
  });

  it('renders the components with default values', () => {
    createComponent();

    expect(findGlFormGroup().attributes('label')).toBe('Color');
    expect(findDropdown().props()).toMatchObject({
      category: 'tertiary',
      autoClose: false,
    });
    expect(findSidebarColorPicker().props('value')).toBe(DEFAULT_COLOR.color);
    expect(findSidebarColorView().exists()).toBe(false);
  });

  it('renders the SidebarColorPicker component with custom values', () => {
    createComponent({ workItem: mockSelectedColorWorkItem });

    expect(findSidebarColorPicker().props('value')).toBe(selectedColor);
  });

  it.each`
    color                  | inputColor       | successHandler
    ${selectedColor}       | ${selectedColor} | ${successUpdateWorkItemMutationHandler}
    ${DEFAULT_COLOR.color} | ${null}          | ${successUpdateWorkItemMutationDefaultColorHandler}
  `(
    'calls update work item mutation with $color when color is changed to $inputColor',
    async ({ color, inputColor, successHandler }) => {
      createComponent({ color, mutationHandler: successHandler });

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

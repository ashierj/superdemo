import { nextTick } from 'vue';
import { GlDisclosureDropdown, GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import BranchSelector from 'ee/security_orchestration/components/policy_editor/branch_selector.vue';
import BranchSelectorPopover from 'ee/security_orchestration/components/policy_editor/branch_selector_popover.vue';
import { PROTECTED_BRANCH } from 'ee/security_orchestration/components/policy_editor/constants';

describe('BranchSelector', () => {
  let wrapper;

  const VALID_BRANCHES = [
    {
      fullPath: 'project',
      name: 'test',
      value: 'test@project_0',
    },
    {
      fullPath: 'project',
      name: 'test1',
      value: 'test1@project_1',
    },
  ];

  const VALID_BRANCHES_YAML_FORMAT = [
    {
      full_path: 'project',
      name: 'test',
      type: PROTECTED_BRANCH,
    },
    {
      full_path: 'project',
      name: 'test1',
      type: PROTECTED_BRANCH,
    },
  ];

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(BranchSelector, {
      propsData,
      stubs: {
        GlDisclosureDropdown: stubComponent(GlDisclosureDropdown, {
          methods: { close: jest.fn() },
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findBranchTypeSelector = () => wrapper.findComponent(GlCollapsibleListbox);
  const findAllListboxItems = () => wrapper.findAllComponents(GlListboxItem);
  const findBranchSelectorPopover = () => wrapper.findComponent(BranchSelectorPopover);
  const findEmptyState = () => wrapper.findByTestId('empty-state');
  const findDoneButton = () => wrapper.findByTestId('done-button');
  const findResetButton = () => wrapper.findByTestId('reset-button');
  const findAddAnotherButton = () => wrapper.findByTestId('add-button');

  describe('initial state for regular branches', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should render required components', () => {
      expect(findDropdown().exists()).toBe(true);
      expect(findEmptyState().exists()).toBe(true);
      expect(findResetButton().exists()).toBe(false);
      expect(findBranchSelectorPopover().exists()).toBe(false);

      expect(findBranchTypeSelector().exists()).toBe(true);
      expect(findAllListboxItems()).toHaveLength(0);

      expect(findDropdown().props('toggleText')).toBe('Choose exception branches');
    });

    it('selects branches', async () => {
      findBranchTypeSelector().vm.$emit('select', PROTECTED_BRANCH);
      await nextTick();

      expect(findBranchSelectorPopover().exists()).toBe(true);
      expect(findBranchSelectorPopover().props('forProtectedBranches')).toBe(true);
      expect(findBranchSelectorPopover().props('show')).toBe(true);

      findBranchSelectorPopover().vm.$emit('add-branches', VALID_BRANCHES);

      await nextTick();

      expect(findBranchSelectorPopover().exists()).toBe(false);

      findDoneButton().vm.$emit('click');

      expect(wrapper.emitted('select-branches')).toEqual([[VALID_BRANCHES_YAML_FORMAT]]);
    });
  });

  describe('existing exceptions', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          selectedExceptions: VALID_BRANCHES_YAML_FORMAT,
        },
      });
    });

    it('renders existing exceptions', () => {
      expect(findAllListboxItems()).toHaveLength(VALID_BRANCHES_YAML_FORMAT.length);
      expect(findDropdown().props('toggleText')).toBe('test, test1');
      expect(findDoneButton().exists()).toBe(true);
      expect(findAddAnotherButton().exists()).toBe(true);
      expect(findResetButton().exists()).toBe(true);
    });

    it('resets all branches', async () => {
      findResetButton().vm.$emit('click');
      await nextTick();

      expect(findEmptyState().exists()).toBe(true);
      expect(wrapper.emitted('select-branches')).toEqual([[[]]]);
    });

    it('unselects single branch', async () => {
      findAllListboxItems().at(0).vm.$emit('select');
      await nextTick();

      findDoneButton().vm.$emit('click');
      await nextTick();

      expect(wrapper.emitted('select-branches')).toEqual([[[VALID_BRANCHES_YAML_FORMAT[1]]]]);
    });

    it('can add more branches', async () => {
      findAddAnotherButton().vm.$emit('click');
      await nextTick();

      expect(findBranchSelectorPopover().props('forProtectedBranches')).toBe(true);
      expect(findBranchSelectorPopover().props('branches')).toEqual(VALID_BRANCHES);

      const newBranches = [
        ...VALID_BRANCHES,
        {
          fullPath: 'project',
          name: 'test3',
          value: 'test3@project_1',
        },
      ];

      findBranchSelectorPopover().vm.$emit('add-branches', newBranches);

      await nextTick();

      expect(findBranchSelectorPopover().exists()).toBe(false);

      findDoneButton().vm.$emit('click');

      const expected = [
        ...VALID_BRANCHES_YAML_FORMAT,
        {
          full_path: 'project',
          name: 'test3',
          type: PROTECTED_BRANCH,
        },
      ];

      expect(wrapper.emitted('select-branches')).toEqual([[expected]]);
    });
  });
});

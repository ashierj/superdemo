import { GlButton, GlFormTextarea, GlPopover, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BranchSelectorPopover from 'ee/security_orchestration/components/policy_editor/branch_selector_popover.vue';

describe('BranchSelectorPopover', () => {
  let wrapper;

  const VALID_BRANCHES_STRING = 'test@project, test1@project';
  const BRANCHES_WITHOUT_PROJECT_STRING = 'test@project, test1';
  const BRANCHES_WITH_DUPLICATES_STRING = 'test@project, test@project, test2@project';

  const VALID_BRANCHES = [
    {
      full_path: 'project',
      name: 'test',
      type: 'protected',
      value: 'test@project',
    },
    {
      full_path: 'project',
      name: 'test1',
      type: 'protected',
      value: 'test1@project',
    },
  ];

  const INVALID_BRANCHES = [
    {
      invalid_path: 'project',
      invalid_name: 'test',
      invalid_type: 'protected',
    },
    {
      invalid_path: 'project',
      invalid_name: 'test1',
      invalid_type: 'protected',
    },
  ];

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(BranchSelectorPopover, {
      propsData,
      provide: {
        namespacePath: 'gitlab-policies',
      },
    });
  };

  const findPopover = () => wrapper.findComponent(GlPopover);
  const findAddButton = () => wrapper.findComponent(GlButton);
  const findTextArea = () => wrapper.findComponent(GlFormTextarea);
  const findDescription = () => wrapper.findComponent(GlSprintf);
  const findValidationError = () => wrapper.findByTestId('validation-error');
  const findDuplicationError = () => wrapper.findByTestId('duplicate-error');

  describe('initial state for regular branches', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should render required components', () => {
      expect(findAddButton().exists()).toBe(true);
      expect(findDescription().exists()).toBe(true);

      expect(findTextArea().props('value')).toBe('');
      expect(findPopover().props('title')).toBe('Add regular branches');
    });

    it('adds new branches', async () => {
      findTextArea().vm.$emit('input', VALID_BRANCHES_STRING);
      await findAddButton().vm.$emit('click');

      expect(wrapper.emitted('add-branches')).toEqual([
        [
          [
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
          ],
        ],
      ]);
    });

    it('adds current project path to branches without full path on project level', async () => {
      findTextArea().vm.$emit('input', BRANCHES_WITHOUT_PROJECT_STRING);
      await findAddButton().vm.$emit('click');

      expect(wrapper.emitted('add-branches')).toEqual([
        [
          [
            {
              fullPath: 'project',
              name: 'test',
              value: 'test@project_0',
            },
            {
              fullPath: 'gitlab-policies',
              name: 'test1',
              value: 'test1@gitlab-policies_1',
            },
          ],
        ],
      ]);
    });

    it('should validate input for duplicates', async () => {
      findTextArea().vm.$emit('input', BRANCHES_WITH_DUPLICATES_STRING);
      await findAddButton().vm.$emit('click');

      expect(findDuplicationError().exists()).toBe(true);
      expect(wrapper.emitted('add-branches')).toBeUndefined();
    });
  });

  describe('has validation', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          hasValidation: true,
        },
      });
    });

    it('validates branches without full path on project level', async () => {
      findTextArea().vm.$emit('input', BRANCHES_WITHOUT_PROJECT_STRING);
      await findAddButton().vm.$emit('click');

      expect(findValidationError().exists()).toBe(true);
      expect(wrapper.emitted('add-branches')).toBeUndefined();
    });
  });

  describe('existing branches', () => {
    it.each`
      branches            | expectedResult
      ${VALID_BRANCHES}   | ${VALID_BRANCHES_STRING}
      ${INVALID_BRANCHES} | ${''}
    `('renders existing branches in textarea', ({ branches, expectedResult }) => {
      createComponent({
        propsData: {
          branches,
        },
      });

      expect(findTextArea().props('value')).toBe(expectedResult);
    });

    it('emits same branches when there are now changes', () => {
      createComponent({
        propsData: {
          branches: VALID_BRANCHES,
        },
      });

      expect(findTextArea().props('value')).toBe(VALID_BRANCHES_STRING);

      findAddButton().vm.$emit('click');

      expect(wrapper.emitted('add-branches')).toEqual([
        [
          [
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
          ],
        ],
      ]);
    });
  });

  describe('branches type', () => {
    it.each`
      forProtectedBranches | title
      ${true}              | ${'Add protected branches'}
      ${false}             | ${'Add regular branches'}
    `('renders correct header for branch type', ({ forProtectedBranches, title }) => {
      createComponent({
        propsData: {
          forProtectedBranches,
        },
      });

      expect(findPopover().props('title')).toBe(title);
    });
  });

  describe('popover state', () => {
    it('renders correct popover state', () => {
      createComponent({
        propsData: {
          container: 'container',
          placement: 'left',
          target: 'target',
        },
      });

      expect(findPopover().props('container')).toBe('container');
      expect(findPopover().props('placement')).toBe('left');
      expect(findPopover().props('target')).toBe('target');
    });
  });
});

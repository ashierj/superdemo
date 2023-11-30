import { nextTick } from 'vue';
import { GlSprintf, GlCollapsibleListbox, GlFormInput } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import CodeBlockAction from 'ee/security_orchestration/components/policy_editor/scan_execution/action/code_block_action.vue';
import CodeBlockImport from 'ee/security_orchestration/components/policy_editor/scan_execution/action/code_block_import.vue';
import PolicyPopover from 'ee/security_orchestration/components/policy_popover.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import YamlEditor from 'ee/security_orchestration/components/yaml_editor.vue';
import {
  CUSTOM_ACTION_KEY,
  INSERTED_CODE_BLOCK,
  LINKED_EXISTING_FILE,
} from 'ee/security_orchestration/components/policy_editor/scan_execution/constants';

describe('CodeBlockAction', () => {
  let wrapper;

  const createComponent = ({ mountFunction = shallowMount, propsData = {}, provide = {} } = {}) => {
    wrapper = mountFunction(CodeBlockAction, {
      propsData: {
        initAction: {
          scan: 'custom',
        },
        ...propsData,
      },
      provide: {
        namespaceType: NAMESPACE_TYPES.GROUP,
        namespacePath: 'gitlab-org',
        ...provide,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findYamlEditor = () => wrapper.findComponent(YamlEditor);
  const findListBox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findCodeBlockActionTooltip = () => wrapper.findComponent(PolicyPopover);
  const findGlFormInput = () => wrapper.findComponent(GlFormInput);
  const findCodeBlockImport = () => wrapper.findComponent(CodeBlockImport);

  describe('default state', () => {
    it('should render yaml editor in default state', async () => {
      createComponent();
      await waitForPromises();
      expect(findYamlEditor().exists()).toBe(true);
      expect(findCodeBlockActionTooltip().exists()).toBe(true);
      expect(findListBox().props('selected')).toBe('');
      expect(findListBox().props('toggleText')).toBe('Choose a method to execute code');
      expect(findCodeBlockImport().props('hasExistingCode')).toBe(false);
    });
  });

  describe('code block', () => {
    it('should render the import button when code exists', async () => {
      createComponent();
      await waitForPromises();
      await findYamlEditor().vm.$emit('input', 'foo: bar');
      expect(findCodeBlockImport().props('hasExistingCode')).toBe(true);
    });

    it('updates the yaml when a file is imported', async () => {
      const fileContents = 'foo: bar';
      createComponent();
      await waitForPromises();
      await findCodeBlockImport().vm.$emit('changed', fileContents);
      expect(findYamlEditor().props('value')).toBe(fileContents);
      expect(findCodeBlockImport().props('hasExistingCode')).toBe(true);
    });
  });

  describe('linked file mode', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should render file path form', async () => {
      await findListBox().vm.$emit('select', LINKED_EXISTING_FILE);

      expect(findListBox().props('selected')).toBe(LINKED_EXISTING_FILE);

      expect(findYamlEditor().exists()).toBe(false);
      expect(findGlFormInput().exists()).toBe(true);
    });

    it('should set file path', async () => {
      await findListBox().vm.$emit('select', LINKED_EXISTING_FILE);

      findGlFormInput().vm.$emit('input', 'file/path');

      expect(wrapper.emitted('changed')).toEqual([
        [{ scan: CUSTOM_ACTION_KEY }],
        [{ scan: 'custom', ci_configuration_path: { file: 'file/path' } }],
      ]);
    });

    it('should reset action when action type is changed', async () => {
      await findListBox().vm.$emit('select', LINKED_EXISTING_FILE);
      await findListBox().vm.$emit('select', INSERTED_CODE_BLOCK);

      expect(wrapper.emitted('changed')).toEqual([
        [{ scan: CUSTOM_ACTION_KEY }],
        [{ scan: CUSTOM_ACTION_KEY }],
      ]);
    });
  });

  describe('error state', () => {
    it('should render error when file path is empty', async () => {
      createComponent({
        mountFunction: mount,
        propsData: {
          initAction: {
            ci_configuration_path: {
              file: 'file',
            },
          },
        },
      });

      expect(findGlFormInput().element.classList.contains('is-valid')).toBe(true);

      /**
       * Can only be tested with set props
       * Because initially rendered empty string
       * won't trigger error state
       */
      wrapper.setProps({
        initAction: {
          ci_configuration_path: {
            file: '',
          },
        },
      });

      await nextTick();

      expect(findGlFormInput().element.classList.contains('is-invalid')).toBe(true);
    });
  });

  describe('existing linked file', () => {
    it('should render linked file mode when file exist', () => {
      createComponent({
        propsData: {
          initAction: {
            ci_configuration_path: {
              file: 'file',
            },
          },
        },
      });

      expect(findListBox().props('selected')).toBe(LINKED_EXISTING_FILE);
      expect(findGlFormInput().attributes('value')).toBe('file');
    });
  });
});

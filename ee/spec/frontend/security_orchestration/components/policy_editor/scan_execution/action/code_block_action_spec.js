import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import CodeBlockSourceSelector from 'ee/security_orchestration/components/policy_editor/scan_execution/action/code_block_source_selector.vue';
import CodeBlockAction from 'ee/security_orchestration/components/policy_editor/scan_execution/action/code_block_action.vue';
import CodeBlockFilePath from 'ee/security_orchestration/components/policy_editor/scan_execution/action/code_block_file_path.vue';
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

  const createComponent = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMount(CodeBlockAction, {
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

  const findCodeBlockFilePath = () => wrapper.findComponent(CodeBlockFilePath);
  const findCodeBlockSourceSelector = () => wrapper.findComponent(CodeBlockSourceSelector);
  const findYamlEditor = () => wrapper.findComponent(YamlEditor);
  const findCodeBlockActionTooltip = () => wrapper.findComponent(PolicyPopover);
  const findCodeBlockImport = () => wrapper.findComponent(CodeBlockImport);

  describe('default state', () => {
    it('should render yaml editor in default state', async () => {
      createComponent();

      await waitForPromises();
      expect(findYamlEditor().exists()).toBe(true);
      expect(findCodeBlockActionTooltip().exists()).toBe(true);
      expect(findCodeBlockSourceSelector().props('selectedType')).toBe(INSERTED_CODE_BLOCK);
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
      await findCodeBlockSourceSelector().vm.$emit('select', LINKED_EXISTING_FILE);

      expect(findYamlEditor().exists()).toBe(false);
      expect(findCodeBlockFilePath().exists()).toBe(true);
    });

    it('should set file path', async () => {
      await findCodeBlockSourceSelector().vm.$emit('select', LINKED_EXISTING_FILE);

      findCodeBlockFilePath().vm.$emit('update-file-path', 'file/path');

      expect(wrapper.emitted('changed')).toEqual([
        [{ scan: CUSTOM_ACTION_KEY }],
        [{ scan: 'custom', ci_configuration_path: { file: 'file/path' } }],
      ]);
    });

    it('should reset action when action type is changed', async () => {
      await findCodeBlockSourceSelector().vm.$emit('select', LINKED_EXISTING_FILE);
      await findCodeBlockFilePath().vm.$emit('select-type', INSERTED_CODE_BLOCK);

      expect(wrapper.emitted('changed')).toEqual([
        [{ scan: CUSTOM_ACTION_KEY }],
        [{ scan: CUSTOM_ACTION_KEY }],
      ]);
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

      expect(findCodeBlockFilePath().props('selectedType')).toBe(LINKED_EXISTING_FILE);
      expect(findCodeBlockFilePath().props('filePath')).toBe('file');
    });

    it('should render linked file mode when project exist', () => {
      createComponent({
        propsData: {
          initAction: {
            ci_configuration_path: {
              project: 'file',
            },
          },
        },
      });

      expect(findCodeBlockFilePath().props('selectedType')).toBe(LINKED_EXISTING_FILE);
      expect(findCodeBlockFilePath().props('selectedProject')).toEqual({ fullPath: 'file' });
    });

    it('should render linked file mode when project id exist', () => {
      createComponent({
        propsData: {
          initAction: {
            ci_configuration_path: {
              id: 'id',
            },
          },
        },
      });

      expect(findCodeBlockFilePath().props('selectedType')).toBe(LINKED_EXISTING_FILE);
      expect(findCodeBlockFilePath().props('selectedProject')).toEqual({
        id: 'gid://gitlab/Project/id',
      });
    });

    it('should render linked file mode when project id exist and ref is selected', () => {
      createComponent({
        propsData: {
          initAction: {
            ci_configuration_path: {
              ref: 'ref',
            },
          },
        },
      });

      expect(findCodeBlockFilePath().props('selectedType')).toBe(LINKED_EXISTING_FILE);
      expect(findCodeBlockFilePath().props('selectedProject')).toEqual(null);
      expect(findCodeBlockFilePath().props('selectedRef')).toBe('ref');
    });
  });

  describe('changing linked file parameters', () => {
    beforeEach(() => {
      createComponent();
    });

    it('selects ref', async () => {
      await findCodeBlockSourceSelector().vm.$emit('select', LINKED_EXISTING_FILE);

      findCodeBlockFilePath().vm.$emit('select-ref', 'ref');

      expect(wrapper.emitted('changed')[1]).toEqual([
        { ci_configuration_path: { ref: 'ref' }, scan: 'custom' },
      ]);
    });

    it('selects type', async () => {
      await findCodeBlockSourceSelector().vm.$emit('select', LINKED_EXISTING_FILE);

      await findCodeBlockFilePath().vm.$emit('select-type', INSERTED_CODE_BLOCK);

      expect(wrapper.emitted('changed')[1]).toEqual([{ scan: 'custom' }]);
      expect(findCodeBlockSourceSelector().props('selectedType')).toBe(INSERTED_CODE_BLOCK);
    });

    it('updates file path', async () => {
      await findCodeBlockSourceSelector().vm.$emit('select', LINKED_EXISTING_FILE);

      findCodeBlockFilePath().vm.$emit('update-file-path', 'file-path');

      expect(wrapper.emitted('changed')[1]).toEqual([
        { ci_configuration_path: { file: 'file-path' }, scan: 'custom' },
      ]);
    });

    it('updates project', async () => {
      const project = {
        id: 'gid://gitlab/Project/29',
        fullPath: 'project-path',
      };

      await findCodeBlockSourceSelector().vm.$emit('select', LINKED_EXISTING_FILE);

      await findCodeBlockFilePath().vm.$emit('select-project', project);

      expect(wrapper.emitted('changed')[1]).toEqual([
        { ci_configuration_path: { id: 29, project: project.fullPath }, scan: 'custom' },
      ]);
    });
  });
});

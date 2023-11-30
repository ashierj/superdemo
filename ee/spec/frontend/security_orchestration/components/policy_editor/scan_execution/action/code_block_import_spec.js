import { GlModal, GlTruncate } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import CodeBlockImport from 'ee/security_orchestration/components/policy_editor/scan_execution/action/code_block_import.vue';

describe('CodeBlockImport', () => {
  let wrapper;
  const fileOneText = 'foo: bar';
  const fileTwoText = 'fizz: buzz';
  const fileOneName = 'code-block.yml';
  const fileTwoName = 'best-code-block.yml';
  const fileOne = new File([fileOneText], fileOneName);
  const fileTwo = new File([fileTwoText], fileTwoName);

  const uploadFile = async (file) => {
    const input = wrapper.find('input[type="file"]');
    Object.defineProperty(input.element, 'files', { value: [file], configurable: true });
    input.trigger('change', file);
    // when loading a file, two waits are needed as it is a multi-step process
    await waitForPromises();
    await waitForPromises();
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMount(CodeBlockImport, {
      propsData: {
        hasExistingCode: false,
        ...propsData,
      },
    });
  };

  const findStatus = () => wrapper.findComponent(GlTruncate);
  const findUploadButton = () => wrapper.find('label');
  const findConfirmationModal = () => wrapper.findComponent(GlModal);

  describe('initial load', () => {
    it('renders the correct components', () => {
      createComponent();
      expect(findUploadButton().exists()).toBe(true);
      expect(findStatus().exists()).toBe(false);
      expect(findConfirmationModal().props('visible')).toBe(false);
    });
  });

  describe('uploading a file', () => {
    beforeEach(() => {
      jest.spyOn(FileReader.prototype, 'readAsText');
      createComponent();
    });

    it('does not show the confirmation modal', async () => {
      await uploadFile(fileOne);
      expect(findConfirmationModal().props('visible')).toBe(false);
    });

    it('uploads the file contents', async () => {
      await uploadFile(fileOne);
      expect(FileReader.prototype.readAsText).toHaveBeenCalledWith(fileOne);
      expect(wrapper.emitted('changed')[0]).toStrictEqual([fileOneText]);
    });

    it('shows the success status', async () => {
      await uploadFile(fileOne);
      expect(findStatus().exists()).toBe(true);
      expect(findStatus().props('text')).toBe(`${fileOneName} loaded succeeded.`);
    });
  });

  describe('uploading a file that overwrites code', () => {
    beforeEach(() => {
      createComponent({ propsData: { hasExistingCode: true } });
    });

    it('shows the confirmation modal on upload', async () => {
      await uploadFile(fileOne);
      expect(wrapper.emitted('changed')).toBeUndefined();
      expect(findConfirmationModal().props('visible')).toBe(true);
    });

    it('uploads the file contents on confirm', async () => {
      await uploadFile(fileOne);
      await findConfirmationModal().vm.$emit('primary');
      expect(findConfirmationModal().props('visible')).toBe(false);
      expect(wrapper.emitted('changed')[0]).toStrictEqual([fileOneText]);
    });

    it('does not overwrite the code on cancel', async () => {
      await uploadFile(fileOne);
      await findConfirmationModal().vm.$emit('secondary');
      expect(findConfirmationModal().props('visible')).toBe(false);
      expect(wrapper.emitted('changed')).toBeUndefined();
    });

    it('uploads the file contents on confirm multiple times', async () => {
      await uploadFile(fileOne);
      await findConfirmationModal().vm.$emit('primary');
      await uploadFile(fileTwo);
      await findConfirmationModal().vm.$emit('primary');
      expect(findConfirmationModal().props('visible')).toBe(false);
      expect(findStatus().props('text')).toBe(`${fileTwoName} loaded succeeded.`);
      expect(wrapper.emitted('changed')).toHaveLength(2);
      expect(wrapper.emitted('changed')[1]).toStrictEqual([fileTwoText]);
    });
  });
});

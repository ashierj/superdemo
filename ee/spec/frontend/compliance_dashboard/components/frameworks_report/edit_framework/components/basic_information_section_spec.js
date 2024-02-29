import * as Utils from 'ee/groups/settings/compliance_frameworks/utils';
import BasicInformationSection from 'ee/compliance_dashboard/components/frameworks_report/edit_framework/components/basic_information_section.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

describe('Basic information section', () => {
  let wrapper;
  const fakeFramework = {
    id: '1',
    name: 'Foo',
    description: 'Bar',
    pipelineConfigurationFullPath: null,
    color: null,
  };

  const provideData = {
    pipelineConfigurationFullPathEnabled: true,
    pipelineConfigurationEnabled: true,
  };

  const invalidFeedback = (input) =>
    input.closest('[role=group].is-invalid').querySelector('.invalid-feedback').textContent;

  function createComponent() {
    return mountExtended(BasicInformationSection, {
      provide: provideData,
      propsData: {
        value: fakeFramework,
      },
      stubs: {
        ColorPicker: true,
      },
    });
  }

  beforeEach(() => {
    wrapper = createComponent();
  });

  it.each([['Name'], ['Description']])(
    'validates required state for field %s',
    async (fieldName) => {
      const input = wrapper.findByLabelText(fieldName);
      await input.setValue('');

      expect(invalidFeedback(input.element)).toContain('is required');

      expect(wrapper.emitted('valid').at(-1)).toStrictEqual([false]);
    },
  );

  it.each`
    pipelineConfigurationFullPath | message
    ${'foo.yml@bar/baz'}          | ${'Configuration not found'}
    ${'foobar'}                   | ${'Invalid format'}
  `(
    'sets the correct invalid message for pipeline',
    async ({ pipelineConfigurationFullPath, message }) => {
      jest.spyOn(Utils, 'fetchPipelineConfigurationFileExists').mockReturnValue(false);

      const pipelineInput = wrapper.findByLabelText('Compliance pipeline configuration (optional)');
      await pipelineInput.setValue(pipelineConfigurationFullPath);
      await waitForPromises();

      expect(invalidFeedback(pipelineInput.element)).toBe(message);
    },
  );
});

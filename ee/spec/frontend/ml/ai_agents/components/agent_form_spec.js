import { GlButton, GlFormInput, GlFormTextarea, GlAlert } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import AgentForm from 'ee/ml/ai_agents/components/agent_form.vue';

describe('AI Agents Form', () => {
  let wrapper;

  const defaultPropsData = {
    buttonLabel: 'Create agent',
    errorMessage: '',
    loading: false,
  };

  const createComponent = (props = {}) => {
    wrapper = mountExtended(AgentForm, {
      provide: { projectPath: 'path/to/project' },
      propsData: {
        ...defaultPropsData,
        ...props,
      },
    });
  };

  const findTextInput = () => wrapper.findComponent(GlFormInput);
  const findTextareaInput = () => wrapper.findComponent(GlFormTextarea);
  const findSubmitButton = () => wrapper.findComponent(GlButton);
  const findAlert = () => wrapper.findComponent(GlAlert);

  it('shows the expected input fields', () => {
    createComponent();
    expect(findTextInput().exists()).toBe(true);
    expect(findTextareaInput().exists()).toBe(true);
  });

  it('configures the form with default props', () => {
    createComponent();

    expect(findSubmitButton().text()).toEqual('Create agent');
    expect(findSubmitButton().text()).not.toBeDisabled();
    expect(findAlert().exists()).toBe(false);
  });

  it('shows a submit button with a configurable label', () => {
    createComponent({ buttonLabel: 'foo' });

    expect(findSubmitButton().exists()).toBe(true);
    expect(findSubmitButton().text()).toEqual('foo');
  });

  it('shows an alert if there is an error message', () => {
    createComponent({ errorMessage: 'some error message' });

    expect(findAlert().exists()).toBe(true);
    expect(findAlert().text()).toEqual('some error message');
  });

  it('disables the input button when in a loading state', () => {
    createComponent({ loading: true });

    expect(findSubmitButton().props('loading')).toBe(true);
  });

  it('emits an event with the form data when the form is submitted', async () => {
    createComponent();

    await findTextInput().vm.$emit('input', 'agent_1');
    await findTextareaInput().vm.$emit('input', 'Do something');

    wrapper.find('form').trigger('submit.prevent');

    expect(wrapper.emitted('submit')[0][0]).toEqual({
      projectPath: 'path/to/project',
      name: 'agent_1',
      prompt: 'Do something',
    });
  });
});

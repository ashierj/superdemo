import {
  GlButton,
  GlFormInput,
  GlFormTextarea,
  GlForm,
  GlExperimentBadge,
  GlAlert,
} from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { CreateAgent } from 'ee/ml/ai_agents/apps';
import createAiAgentMutation from 'ee/ml/ai_agents/graphql/mutations/create_ai_agent.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { createAiAgentsResponses } from '../graphql/mocks';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('ee/ml/ai_agents/apps/create_agent', () => {
  let wrapper;
  let apolloProvider;

  Vue.use(VueApollo);

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  const mountComponent = (
    resolver = jest.fn().mockResolvedValue(createAiAgentsResponses.success),
  ) => {
    const requestHandlers = [[createAiAgentMutation, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(CreateAgent, {
      apolloProvider,
      propsData: { projectPath: 'project/path' },
    });
  };

  const findTitleArea = () => wrapper.findComponent(TitleArea);
  const findBadge = () => wrapper.findComponent(GlExperimentBadge);
  const findButton = () => wrapper.findComponent(GlButton);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findTextarea = () => wrapper.findComponent(GlFormTextarea);
  const findForm = () => wrapper.findComponent(GlForm);
  const findErrorAlert = () => wrapper.findComponent(GlAlert);

  const submitForm = async () => {
    findForm().vm.$emit('submit', { preventDefault: () => {} });
    await waitForPromises();
  };

  it('shows the title', () => {
    mountComponent();

    expect(findTitleArea().text()).toContain('New agent');
  });

  it('displays the experiment badge', () => {
    mountComponent();

    expect(findBadge().exists()).toBe(true);
  });

  it('renders the button', () => {
    mountComponent();

    expect(findButton().text()).toBe('Create agent');
  });

  it('submits the query with correct parameters', async () => {
    const resolver = jest.fn().mockResolvedValue(createAiAgentMutation.success);
    mountComponent(resolver);

    findInput().vm.$emit('input', 'agent_1');
    findTextarea().vm.$emit('input', 'Do something');

    await submitForm();

    expect(resolver).toHaveBeenLastCalledWith(
      expect.objectContaining({
        projectPath: 'project/path',
        name: 'agent_1',
        prompt: 'Do something',
      }),
    );
  });

  it('navigates to the new page when result is successful', async () => {
    mountComponent();

    await submitForm();

    expect(visitUrl).toHaveBeenCalledWith('/some/project/-/ml/agents/1');
  });

  it('shows errors when result is a top level error', async () => {
    const error = new Error('Failure!');
    mountComponent(jest.fn().mockRejectedValue({ error }));

    await submitForm();

    expect(findErrorAlert().text()).toBe('An error has occurred when saving the agent.');
    expect(visitUrl).not.toHaveBeenCalled();
  });

  it('shows errors when result is a validation error', async () => {
    mountComponent(jest.fn().mockResolvedValue(createAiAgentsResponses.validationFailure));

    await submitForm();

    expect(findErrorAlert().text()).toBe("Name is invalid, Name can't be blank");
    expect(visitUrl).not.toHaveBeenCalled();
  });
});

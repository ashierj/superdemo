import { GlButton, GlLoadingIcon, GlCollapsibleListbox, GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import VueApollo from 'vue-apollo';
import { createMockSubscription } from 'mock-apollo-client';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import aiActionMutation from 'ee/graphql_shared/mutations/ai_action.mutation.graphql';
import Api from 'ee/api';
import vulnerabilityStateMutations from 'ee/security_dashboard/graphql/mutate_vulnerability_state';
import SplitButton from 'ee/vue_shared/security_reports/components/split_button.vue';
import StatusBadge from 'ee/vue_shared/security_reports/components/status_badge.vue';
import Header from 'ee/vulnerabilities/components/header.vue';
import ResolutionAlert from 'ee/vulnerabilities/components/resolution_alert.vue';
import StatusDescription from 'ee/vulnerabilities/components/status_description.vue';
import VulnerabilityStateDropdown from 'ee/vulnerabilities/components/vulnerability_state_dropdown.vue';
import { FEEDBACK_TYPES, VULNERABILITY_STATE_OBJECTS } from 'ee/vulnerabilities/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import UsersMockHelper from 'helpers/user_mock_data_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import download from '~/lib/utils/downloader';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import * as urlUtility from '~/lib/utils/url_utility';
import {
  getVulnerabilityStatusMutationResponse,
  dismissalDescriptions,
  getAiSubscriptionResponse,
  AI_SUBSCRIPTION_ERROR_RESPONSE,
  MUTATION_AI_ACTION_DEFAULT_RESPONSE,
  MUTATION_AI_ACTION_GLOBAL_ERROR,
  MUTATION_AI_ACTION_ERROR,
} from './mock_data';

Vue.use(VueApollo);

const MOCK_SUBSCRIPTION_RESPONSE = getAiSubscriptionResponse(
  'http://gdk.test:3000/secure-ex/webgoat.net/-/merge_requests/5',
);
const vulnerabilityStateEntries = Object.entries(VULNERABILITY_STATE_OBJECTS);
const mockAxios = new MockAdapter(axios);
jest.mock('~/alert');
jest.mock('~/lib/utils/downloader');

describe('Vulnerability Header', () => {
  let wrapper;

  const defaultVulnerability = {
    id: 1,
    createdAt: new Date().toISOString(),
    reportType: 'dast',
    state: 'detected',
    createMrUrl: '/create_mr_url',
    newIssueUrl: '/new_issue_url',
    projectFingerprint: 'abc123',
    uuid: 'xxxxxxxx-xxxx-5xxx-xxxx-xxxxxxxxxxxx',
    pipeline: {
      id: 2,
      createdAt: new Date().toISOString(),
      url: 'pipeline_url',
      sourceBranch: 'main',
    },
    description: 'description',
    identifiers: 'identifiers',
    links: 'links',
    location: 'location',
    name: 'name',
    mergeRequestLinks: [],
    stateTransitions: [],
  };

  const diff = 'some diff to download';

  const getVulnerability = ({
    canCreateMergeRequest,
    canDownloadPatch,
    canResolveWithAI,
    canAdmin = true,
  }) => ({
    remediations: canCreateMergeRequest || canDownloadPatch ? [{ diff }] : null,
    state: canDownloadPatch ? 'detected' : 'resolved',
    mergeRequestLinks: canCreateMergeRequest || canDownloadPatch ? [] : [{}],
    mergeRequestFeedback: canCreateMergeRequest ? null : {},
    canAdmin,
    ...(canResolveWithAI ? { reportType: 'sast' } : {}),
    ...(canDownloadPatch && canCreateMergeRequest === undefined ? { createMrUrl: '' } : {}),
  });

  const createApolloProvider = (...queries) => {
    return createMockApollo([...queries]);
  };

  const createRandomUser = () => {
    const user = UsersMockHelper.createRandomUser();
    const url = Api.buildUrl(Api.userPath).replace(':id', user.id);
    mockAxios.onGet(url).replyOnce(HTTP_STATUS_OK, user);

    return user;
  };

  const findGlButton = () => wrapper.findComponent(GlButton);
  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findStatusBadge = () => wrapper.findComponent(StatusBadge);
  const findSplitButton = () => wrapper.findComponent(SplitButton);
  const findStateButton = () => wrapper.findComponent(GlCollapsibleListbox);
  const findResolutionAlert = () => wrapper.findComponent(ResolutionAlert);
  const findStatusDescription = () => wrapper.findComponent(StatusDescription);
  const findBadge = () => wrapper.findComponent(GlBadge);

  // Helpers
  const changeStatus = (action) => {
    const dropdown = wrapper.findComponent(VulnerabilityStateDropdown);
    dropdown.vm.$emit('change', { action });
  };

  const createWrapper = ({ vulnerability = {}, apolloProvider, glFeatures }) => {
    wrapper = shallowMount(Header, {
      apolloProvider,
      propsData: {
        vulnerability: {
          ...defaultVulnerability,
          ...vulnerability,
        },
      },
      provide: {
        dismissalDescriptions,
        glFeatures: {
          resolveVulnerabilityAi: true,
          ...glFeatures,
        },
      },
    });
  };

  afterEach(() => {
    mockAxios.reset();
    createAlert.mockReset();
  });

  describe.each`
    action       | queryName                          | expected
    ${'dismiss'} | ${'vulnerabilityDismiss'}          | ${'dismissed'}
    ${'confirm'} | ${'vulnerabilityConfirm'}          | ${'confirmed'}
    ${'resolve'} | ${'vulnerabilityResolve'}          | ${'resolved'}
    ${'revert'}  | ${'vulnerabilityRevertToDetected'} | ${'detected'}
  `('state dropdown change', ({ action, queryName, expected }) => {
    describe('when API call is successful', () => {
      beforeEach(() => {
        const apolloProvider = createApolloProvider([
          vulnerabilityStateMutations[action],
          jest.fn().mockResolvedValue(getVulnerabilityStatusMutationResponse(queryName, expected)),
        ]);

        createWrapper({ apolloProvider });
      });

      it('shows the loading icon and passes the correct "loading" prop to the status badge', async () => {
        changeStatus(action);
        await nextTick();

        expect(findGlLoadingIcon().exists()).toBe(true);
        expect(findStatusBadge().props('loading')).toBe(true);
      });

      it(`emits the updated vulnerability properly - ${action}`, async () => {
        changeStatus(action);

        await waitForPromises();
        expect(wrapper.emitted('vulnerability-state-change')[0][0]).toMatchObject({
          state: expected,
        });
      });

      it(`emits an event when the state is changed - ${action}`, async () => {
        changeStatus(action);

        await waitForPromises();
        expect(wrapper.emitted()['vulnerability-state-change']).toHaveLength(1);
      });

      it('does not show the loading icon and passes the correct "loading" prop to the status badge', async () => {
        changeStatus(action);
        await waitForPromises();

        expect(findGlLoadingIcon().exists()).toBe(false);
        expect(findStatusBadge().props('loading')).toBe(false);
      });
    });

    describe('when API call is failed', () => {
      beforeEach(() => {
        const apolloProvider = createApolloProvider([
          vulnerabilityStateMutations[action],
          jest.fn().mockRejectedValue({
            data: {
              [queryName]: {
                errors: [{ message: 'Something went wrong' }],
                vulnerability: {},
              },
            },
          }),
        ]);

        createWrapper({ apolloProvider });
      });

      it('when the vulnerability state changes but the API call fails, an error message is displayed', async () => {
        changeStatus(action);

        await waitForPromises();
        expect(createAlert).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('state button', () => {
    it('renders the disabled state button when user can not admin the vulnerability', () => {
      createWrapper({ vulnerability: getVulnerability({ canAdmin: true }) });

      expect(findStateButton().props('disabled')).toBe(false);
    });

    it('renders the enabled state button when user can admin the vulnerability', () => {
      createWrapper({ vulnerability: getVulnerability({ canAdmin: false }) });

      expect(findStateButton().props('disabled')).toBe(true);
    });
  });

  describe('split button', () => {
    it('renders the correct amount of buttons', async () => {
      createWrapper({
        vulnerability: getVulnerability({
          canCreateMergeRequest: true,
          canDownloadPatch: true,
          canResolveWithAI: true,
        }),
      });
      await waitForPromises();
      const buttons = findSplitButton().props('buttons');
      expect(buttons).toHaveLength(3);
    });

    it.each`
      index | name                            | tagline
      ${0}  | ${'Resolve with merge request'} | ${'Automatically apply the patch in a new branch'}
      ${1}  | ${'Download patch to resolve'}  | ${'Download the patch to apply it manually'}
      ${2}  | ${'Resolve with AI'}            | ${'Automatically opens a merge request with a solution generated by AI'}
    `('renders the button for $name at index $index', async ({ index, name, tagline }) => {
      createWrapper({
        vulnerability: getVulnerability({
          canCreateMergeRequest: true,
          canDownloadPatch: true,
          canResolveWithAI: true,
        }),
      });
      await waitForPromises();

      const buttons = findSplitButton().props('buttons');
      expect(buttons[index].name).toBe(name);
      expect(buttons[index].tagline).toBe(tagline);
    });

    it('does not render the split button if there is only one action', () => {
      createWrapper({
        vulnerability: getVulnerability({
          canCreateMergeRequest: false,
          canDownloadPatch: false,
          canResolveWithAI: true,
        }),
      });

      expect(findSplitButton().exists()).toBe(false);
    });
  });

  describe('single action button', () => {
    it('does not display if there are no actions', () => {
      createWrapper({
        vulnerability: getVulnerability({
          canCreateMergeRequest: false,
          canDownloadPatch: false,
          canResolveWithAI: false,
        }),
      });

      expect(findGlButton().exists()).toBe(false);
    });

    it.each`
      state                      | name
      ${'canCreateMergeRequest'} | ${'Resolve with merge request'}
      ${'canDownloadPatch'}      | ${'Download patch to resolve'}
      ${'canResolveWithAI'}      | ${'Resolve with AI Experiment'}
    `('renders the $name button', ({ state, name }) => {
      createWrapper({
        vulnerability: getVulnerability({
          [state]: true,
        }),
      });
      expect(findGlButton().text()).toMatchInterpolatedText(name);
    });

    describe('create merge request', () => {
      beforeEach(() => {
        createWrapper({
          vulnerability: getVulnerability({
            canCreateMergeRequest: true,
          }),
        });
      });

      it('emits createMergeRequest when create merge request button is clicked', async () => {
        const mergeRequestPath = '/group/project/merge_request/123';
        const spy = jest.spyOn(urlUtility, 'redirectTo');
        mockAxios.onPost(defaultVulnerability.createMrUrl).reply(HTTP_STATUS_OK, {
          merge_request_path: mergeRequestPath,
          merge_request_links: [{ merge_request_path: mergeRequestPath }],
        });
        findGlButton().vm.$emit('click');
        await waitForPromises();

        expect(spy).toHaveBeenCalledWith(mergeRequestPath);
        expect(mockAxios.history.post).toHaveLength(1);
        expect(JSON.parse(mockAxios.history.post[0].data)).toMatchObject({
          vulnerability_feedback: {
            feedback_type: FEEDBACK_TYPES.MERGE_REQUEST,
            category: defaultVulnerability.reportType,
            project_fingerprint: defaultVulnerability.projectFingerprint,
            finding_uuid: defaultVulnerability.uuid,
            vulnerability_data: {
              ...convertObjectPropsToSnakeCase(getVulnerability({ canCreateMergeRequest: true })),
              category: defaultVulnerability.reportType,
              state: 'resolved',
            },
          },
        });
      });

      it('shows an error message when merge request creation fails', () => {
        mockAxios
          .onPost(defaultVulnerability.create_mr_url)
          .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        findGlButton().vm.$emit('click');
        return waitForPromises().then(() => {
          expect(mockAxios.history.post).toHaveLength(1);
          expect(createAlert).toHaveBeenCalledWith({
            message: 'There was an error creating the merge request. Please try again.',
          });
        });
      });
    });

    describe('can download patch', () => {
      beforeEach(() => {
        createWrapper({
          vulnerability: getVulnerability({
            canDownloadPatch: true,
          }),
        });
      });

      it('emits downloadPatch when download patch button is clicked', async () => {
        findGlButton().vm.$emit('click');
        await nextTick();
        expect(download).toHaveBeenCalledWith({ fileData: diff, fileName: `remediation.patch` });
      });
    });

    describe('resolve with AI', () => {
      let visitUrlMock;
      let mockSubscription;
      let subscriptionSpy;

      const createWrapperWithAiApollo = ({
        mutationResponse = MUTATION_AI_ACTION_DEFAULT_RESPONSE,
      } = {}) => {
        mockSubscription = createMockSubscription();
        subscriptionSpy = jest.fn().mockReturnValue(mockSubscription);

        const apolloProvider = createMockApollo([[aiActionMutation, mutationResponse]]);
        apolloProvider.defaultClient.setRequestHandler(aiResponseSubscription, subscriptionSpy);

        createWrapper({
          vulnerability: getVulnerability({
            canResolveWithAI: true,
          }),
          apolloProvider,
        });

        return waitForPromises();
      };

      const createWrapperAndClickButton = (params) => {
        createWrapperWithAiApollo(params);
        findGlButton().vm.$emit('click');
      };

      const sendSubscriptionMessage = (aiCompletionResponse) => {
        mockSubscription.next({ data: { aiCompletionResponse } });
        return waitForPromises();
      };

      // When the subscription is ready, a null aiCompletionResponse is sent
      const waitForSubscriptionToBeReady = () => sendSubscriptionMessage(null);

      beforeEach(() => {
        gon.current_user_id = 1;
        visitUrlMock = jest.spyOn(urlUtility, 'visitUrl').mockReturnValue({});
      });

      it('renders the experiment badge', () => {
        createWrapper({
          vulnerability: getVulnerability({
            canResolveWithAI: true,
          }),
        });
        expect(findBadge().text()).toBe('Experiment');
      });

      it('continues to show the loading state into the redirect call', async () => {
        await createWrapperWithAiApollo();

        const resolveAIButton = findGlButton();
        expect(resolveAIButton.props('loading')).toBe(false);

        resolveAIButton.vm.$emit('click');
        await nextTick();
        expect(resolveAIButton.props('loading')).toBe(true);

        await waitForSubscriptionToBeReady();
        expect(resolveAIButton.props('loading')).toBe(true);

        await sendSubscriptionMessage(MOCK_SUBSCRIPTION_RESPONSE);
        expect(resolveAIButton.props('loading')).toBe(true);
        expect(visitUrlMock).toHaveBeenCalledTimes(1);
      });

      it('starts the subscription, waits for the subscription to be ready, then runs the mutation', async () => {
        await createWrapperAndClickButton();
        expect(subscriptionSpy).toHaveBeenCalled();
        expect(MUTATION_AI_ACTION_DEFAULT_RESPONSE).not.toHaveBeenCalled();

        await waitForSubscriptionToBeReady();
        expect(MUTATION_AI_ACTION_DEFAULT_RESPONSE).toHaveBeenCalled();
      });

      it('redirects after it receives the AI response', async () => {
        await createWrapperAndClickButton();
        await waitForSubscriptionToBeReady();
        expect(visitUrlMock).not.toHaveBeenCalled();

        await sendSubscriptionMessage(MOCK_SUBSCRIPTION_RESPONSE);
        expect(visitUrlMock).toHaveBeenCalledTimes(1);
        expect(visitUrlMock).toHaveBeenCalledWith(MOCK_SUBSCRIPTION_RESPONSE.content);
      });

      it.each`
        type                    | mutationResponse                       | subscriptionMessage               | expectedError
        ${'mutation global'}    | ${MUTATION_AI_ACTION_GLOBAL_ERROR}     | ${null}                           | ${'mutation global error'}
        ${'mutation ai action'} | ${MUTATION_AI_ACTION_ERROR}            | ${null}                           | ${'mutation ai action error'}
        ${'subscription'}       | ${MUTATION_AI_ACTION_DEFAULT_RESPONSE} | ${AI_SUBSCRIPTION_ERROR_RESPONSE} | ${'subscription error'}
      `(
        'unsubscribes and shows only an error when there is a $type error',
        async ({ mutationResponse, subscriptionMessage, expectedError }) => {
          await createWrapperAndClickButton({ mutationResponse });
          await waitForSubscriptionToBeReady();
          await sendSubscriptionMessage(subscriptionMessage);

          expect(findGlButton().props('loading')).toBe(false);
          expect(visitUrlMock).not.toHaveBeenCalled();
          expect(createAlert.mock.calls[0][0].message.toString()).toContain(expectedError);
        },
      );
    });
  });

  describe('status description', () => {
    let vulnerability;
    let user;

    beforeEach(() => {
      user = createRandomUser();

      vulnerability = {
        ...defaultVulnerability,
        state: 'confirmed',
        confirmedById: user.id,
      };

      createWrapper({ vulnerability });
    });

    it('the status description is rendered and passed the correct data', () => {
      return waitForPromises().then(() => {
        expect(findStatusDescription().exists()).toBe(true);
        expect(findStatusDescription().props()).toEqual({
          vulnerability,
          user,
          isLoadingVulnerability: false,
          isLoadingUser: false,
          isStatusBolded: false,
        });
      });
    });
  });

  describe('when the vulnerability is no longer detected on the default branch', () => {
    const branchName = 'main';

    beforeEach(() => {
      createWrapper({
        vulnerability: {
          resolvedOnDefaultBranch: true,
          projectDefaultBranch: branchName,
        },
      });
    });

    it('should show the resolution alert component', () => {
      expect(findResolutionAlert().exists()).toBe(true);
    });

    it('should pass down the default branch name', () => {
      expect(findResolutionAlert().props('defaultBranchName')).toEqual(branchName);
    });

    it('the resolution alert component should not be shown if when the vulnerability is already resolved', async () => {
      createWrapper({
        vulnerability: {
          state: 'resolved',
        },
      });
      await nextTick();
      const alert = findResolutionAlert();

      expect(alert.exists()).toBe(false);
    });
  });

  describe('vulnerability user watcher', () => {
    it.each(vulnerabilityStateEntries)(
      `loads the correct user for the vulnerability state "%s"`,
      (state) => {
        const user = createRandomUser();
        createWrapper({ vulnerability: { state, [`${state}ById`]: user.id } });

        return waitForPromises().then(() => {
          expect(mockAxios.history.get).toHaveLength(1);
          expect(findStatusDescription().props('user')).toEqual(user);
        });
      },
    );

    it('does not load a user if there is no user ID', () => {
      createWrapper({ vulnerability: { state: 'detected' } });

      return waitForPromises().then(() => {
        expect(mockAxios.history.get).toHaveLength(0);
        expect(findStatusDescription().props('user')).toBeUndefined();
      });
    });

    it('will show an error when the user cannot be loaded', () => {
      createWrapper({ vulnerability: { state: 'confirmed', confirmedById: 1 } });

      mockAxios.onGet().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      return waitForPromises().then(() => {
        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(mockAxios.history.get).toHaveLength(1);
      });
    });

    it('will set the isLoadingUser property correctly when the user is loading and finished loading', () => {
      const user = createRandomUser();
      createWrapper({ vulnerability: { state: 'confirmed', confirmedById: user.id } });

      expect(findStatusDescription().props('isLoadingUser')).toBe(true);

      return waitForPromises().then(() => {
        expect(mockAxios.history.get).toHaveLength(1);
        expect(findStatusDescription().props('isLoadingUser')).toBe(false);
      });
    });
  });

  describe('when FF "resolveVulnerabilityAi" is disabled', () => {
    describe('split button', () => {
      it('renders the create merge request and issue button as a split button', async () => {
        createWrapper({
          glFeatures: {
            resolveVulnerabilityAi: false,
          },
          vulnerability: getVulnerability({
            canCreateMergeRequest: true,
            canDownloadPatch: true,
          }),
        });
        await waitForPromises();

        expect(findSplitButton().exists()).toBe(true);
        const buttons = findSplitButton().props('buttons');
        expect(buttons).toHaveLength(2);
        expect(buttons[0].name).toBe('Resolve with merge request');
        expect(buttons[1].name).toBe('Download patch to resolve');
      });

      it('does not render the split button if there is only one action', () => {
        createWrapper({
          glFeatures: {
            resolveVulnerabilityAi: false,
          },
          vulnerability: getVulnerability({
            canCreateMergeRequest: true,
          }),
        });
        expect(findSplitButton().exists()).toBe(false);
      });
    });

    it('does not display if there are no actions', () => {
      createWrapper({
        glFeatures: {
          resolveVulnerabilityAi: false,
        },
        vulnerability: getVulnerability({}),
      });
      expect(findGlButton().exists()).toBe(false);
    });
  });
});

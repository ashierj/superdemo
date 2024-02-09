import { GlModal, GlAlert, GlCollapsibleListbox } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ProjectModal from 'ee/security_orchestration/components/policies/project_modal.vue';
import linkSecurityPolicyProject from 'ee/security_orchestration/graphql/mutations/link_security_policy_project.mutation.graphql';
import unlinkSecurityPolicyProject from 'ee/security_orchestration/graphql/mutations/unlink_security_policy_project.mutation.graphql';
import InstanceProjectSelector from 'ee/security_orchestration/components/policies/instance_project_selector.vue';
import {
  POLICY_PROJECT_LINK_ERROR_MESSAGE,
  POLICY_PROJECT_LINK_SUCCESS_MESSAGE,
} from 'ee/security_orchestration/components/policies/constants';
import {
  mockLinkSecurityPolicyProjectResponses,
  mockUnlinkSecurityPolicyProjectResponses,
} from '../../mocks/mock_apollo';

Vue.use(VueApollo);

describe('ProjectModal Component', () => {
  let wrapper;
  const sampleProject = {
    id: 'gid://gitlab/Project/1',
    name: 'Test 1',
  };

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findInstanceProjectSelector = () => wrapper.findComponent(InstanceProjectSelector);
  const findUnlinkButton = () => wrapper.findByLabelText('Unlink project');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findModal = () => wrapper.findComponent(GlModal);

  const selectProject = async ({ project = sampleProject, shouldSubmit = true } = {}) => {
    findInstanceProjectSelector().vm.$emit('projectClicked', project);
    await waitForPromises();

    if (shouldSubmit) {
      findModal().vm.$emit('ok');
      await waitForPromises();
    }
  };

  const createWrapper = ({
    mutationQuery = linkSecurityPolicyProject,
    mutationResult = mockLinkSecurityPolicyProjectResponses.success,
    provide = {},
  } = {}) => {
    wrapper = mountExtended(ProjectModal, {
      apolloProvider: createMockApollo([[mutationQuery, mutationResult]]),
      stubs: {
        GlModal: stubComponent(GlModal, {
          template:
            '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
        }),
      },
      provide: {
        disableSecurityPolicyProject: false,
        documentationPath: 'test/path/index.md',
        namespacePath: 'path/to/project/or/group',
        assignedPolicyProject: null,
        ...provide,
      },
    });
  };

  const createWrapperAndSelectProject = async (data) => {
    createWrapper(data);
    await selectProject();
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('passes down correct properties/attributes to the gl-modal component', () => {
      expect(findModal().props()).toMatchObject({
        modalId: 'scan-new-policy',
        size: 'sm',
        visible: false,
        title: 'Select security project',
      });

      expect(findModal().attributes()).toEqual({
        'ok-disabled': 'true',
        'ok-title': 'Save',
        'cancel-variant': 'light',
      });
    });

    it('displays a placeholder when no project is selected', () => {
      expect(findDropdown().props('toggleText')).toBe('Select a project');
    });

    it('does not display the remove button when no project is selected', () => {
      expect(findUnlinkButton().exists()).toBe(false);
    });

    it('does not display a warning', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  it('emits close event when gl-modal emits change event', async () => {
    createWrapper();
    await selectProject({ shouldSubmit: false });

    findModal().vm.$emit('change');
    expect(wrapper.emitted('close')).toEqual([[]]);
    expect(findInstanceProjectSelector().props('selectedProject').name).toBe('Test 1');

    // should restore the previous state when action is not submitted
    await nextTick();
    expect(findInstanceProjectSelector().props('selectedProject').name).toBeUndefined();
  });

  describe('unlinking project', () => {
    const unlinkText =
      'Unlinking a security project removes all policies stored in the linked security project. Save to confirm this action.';

    it.each`
      mutationResult | expectedVariant | expectedText                                                    | expectedHasPolicyProject
      ${'success'}   | ${'success'}    | ${'Security policy project was unlinked successfully'}          | ${false}
      ${'failure'}   | ${'danger'}     | ${'An error occurred unassigning your security policy project'} | ${true}
    `(
      'unlinks a project and handles $mutationResult case',
      async ({ mutationResult, expectedVariant, expectedText, expectedHasPolicyProject }) => {
        createWrapper({
          mutationQuery: unlinkSecurityPolicyProject,
          mutationResult: mockUnlinkSecurityPolicyProjectResponses[mutationResult],
          provide: { assignedPolicyProject: { id: 'gid://gitlab/Project/0', name: 'Test 0' } },
        });

        // Initial state
        expect(findModal().attributes('ok-disabled')).toBe('true');
        expect(wrapper.findByText(unlinkText).exists()).toBe(false);

        // When we click on the delete button, the component should display a warning
        findUnlinkButton().trigger('click');
        await nextTick();

        expect(wrapper.findByText(unlinkText).exists()).toBe(true);
        expect(findModal().attributes('ok-disabled')).toBeUndefined();

        // Clicking the OK button should submit a GraphQL query
        findModal().vm.$emit('ok');
        await waitForPromises();

        expect(wrapper.emitted('project-updated')).toEqual([
          [
            {
              text: expectedText,
              variant: expectedVariant,
              hasPolicyProject: expectedHasPolicyProject,
            },
          ],
        ]);
      },
    );
  });

  describe('project selection', () => {
    it('enables the "Save" button only if a new project is selected', async () => {
      createWrapper({
        provide: { assignedPolicyProject: { id: 'gid://gitlab/Project/0', name: 'Test 0' } },
      });
      await waitForPromises();

      expect(findModal().attributes('ok-disabled')).toBe('true');

      findInstanceProjectSelector().vm.$emit('projectClicked', {
        id: 'gid://gitlab/Project/1',
        name: 'Test 1',
      });

      await waitForPromises();

      expect(findModal().attributes('ok-disabled')).toBeUndefined();
    });

    it.each`
      messageType  | factoryFn                                                                                                  | text                                   | variant      | hasPolicyProject | selectedProject
      ${'success'} | ${createWrapperAndSelectProject}                                                                           | ${POLICY_PROJECT_LINK_SUCCESS_MESSAGE} | ${'success'} | ${true}          | ${sampleProject}
      ${'failure'} | ${() => createWrapperAndSelectProject({ mutationResult: mockLinkSecurityPolicyProjectResponses.failure })} | ${POLICY_PROJECT_LINK_ERROR_MESSAGE}   | ${'danger'}  | ${false}         | ${undefined}
    `(
      'emits an event with $messageType message',
      async ({ factoryFn, text, variant, hasPolicyProject, selectedProject }) => {
        await factoryFn();

        expect(wrapper.emitted('project-updated')).toEqual([
          [
            {
              text,
              variant,
              hasPolicyProject,
            },
          ],
        ]);

        if (selectedProject) {
          expect(findInstanceProjectSelector().props('selectedProject')).toEqual(selectedProject);
        }
      },
    );

    it('displays the remove button when a project is selected', async () => {
      createWrapper({
        provide: { assignedPolicyProject: { id: 'gid://gitlab/Project/0', name: 'Test 0' } },
      });
      await nextTick();

      expect(findUnlinkButton().exists()).toBe(true);
    });
  });

  describe('disabled', () => {
    beforeEach(() => {
      createWrapper({ provide: { disableSecurityPolicyProject: true } });
    });

    it('disables the dropdown', () => {
      expect(findDropdown().props('disabled')).toBe(true);
    });

    it('displays a warning', () => {
      expect(findAlert().text()).toBe('Only owners can update Security Policy Project');
    });
  });
});

import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import * as Utils from 'ee/groups/settings/compliance_frameworks/utils';
import EditFramework from 'ee/compliance_dashboard/components/frameworks_report/edit_framework/edit_framework.vue';
import DeleteModal from 'ee/compliance_dashboard/components/frameworks_report/edit_framework/components/delete_modal.vue';
import createComplianceFrameworkMutation from 'ee/compliance_dashboard/graphql/mutations/create_compliance_framework.mutation.graphql';
import updateComplianceFrameworkMutation from 'ee/compliance_dashboard/graphql/mutations/update_compliance_framework.mutation.graphql';
import deleteComplianceFrameworkMutation from 'ee/compliance_dashboard/graphql/mutations/delete_compliance_framework.mutation.graphql';
import getComplianceFrameworkQuery from 'ee/graphql_shared/queries/get_compliance_framework.query.graphql';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';

import { createComplianceFrameworksReportResponse } from '../../../mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility');

describe('Edit Framework Form', () => {
  let wrapper;
  const propsData = {
    id: '1',
  };
  const provideData = {
    groupPath: 'group-1',
    pipelineConfigurationFullPathEnabled: true,
    pipelineConfigurationEnabled: true,
  };

  const showDeleteModal = jest.fn();
  const routerBack = jest.fn();

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findError = () => wrapper.findComponent(GlAlert);
  const findDeleteButton = () => wrapper.findByText('Delete framework');
  const findDeleteModal = () => wrapper.findComponent(DeleteModal);

  const invalidFeedback = (input) =>
    input.closest('[role=group]').querySelector('.invalid-feedback').textContent;

  function createComponent(
    mountFn = mountExtended,
    requestHandlers = [],
    routeParams = { id: '1' },
  ) {
    return mountFn(EditFramework, {
      apolloProvider: createMockApollo(requestHandlers),
      provide: provideData,
      propsData,
      stubs: {
        ColorPicker: true,
        DeleteModal: stubComponent(DeleteModal, {
          template: '<div></div>',
          methods: { show: showDeleteModal },
        }),
      },
      mocks: {
        $route: {
          params: routeParams,
        },
        $router: {
          back: routerBack,
        },
      },
    });
  }

  it('renders the loading icon', () => {
    wrapper = createComponent(shallowMountExtended);
    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('renders error if loading fails', async () => {
    wrapper = createComponent(shallowMountExtended);

    await waitForPromises();
    expect(findError().exists()).toBe(true);
  });

  it('does not attempt to load framework if no id provided in url', async () => {
    const queryFn = jest.fn();
    wrapper = createComponent(shallowMountExtended, [[getComplianceFrameworkQuery, queryFn]], {});

    await waitForPromises();
    expect(queryFn).not.toHaveBeenCalled();
  });

  it('loads framework if id provided in url', async () => {
    wrapper = createComponent(mountExtended, [
      [
        getComplianceFrameworkQuery,
        () => ({ ...createComplianceFrameworksReportResponse(), default: true }),
      ],
    ]);

    await waitForPromises();
    const values = Object.fromEntries(new FormData(wrapper.find('form').element));

    expect(values).toStrictEqual({
      name: 'Some framework 0',
      description: 'This is a framework 0',
      pipeline_configuration_full_path: '',
      // JSDOM issue, checking manually:
      // default: true,
    });

    expect(wrapper.find('input[name="default"]').attributes('value')).toBe('true');
  });

  describe('Validation', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('validates required fields', async () => {
      const nameInput = wrapper.findByLabelText('Name');
      const descriptionInput = wrapper.findByLabelText('Description');

      await nameInput.setValue('');
      await descriptionInput.setValue('');

      expect(invalidFeedback(nameInput.element)).toContain('is required');
      expect(invalidFeedback(descriptionInput.element)).toContain('is required');
    });

    it.each`
      pipelineConfigurationFullPath | message
      ${'foo.yml@bar/baz'}          | ${'Configuration not found'}
      ${'foobar'}                   | ${'Invalid format'}
    `(
      'sets the correct invalid message for pipeline',
      async ({ pipelineConfigurationFullPath, message }) => {
        jest.spyOn(Utils, 'fetchPipelineConfigurationFileExists').mockReturnValue(false);

        const pipelineInput = wrapper.findByLabelText(
          'Compliance pipeline configuration (optional)',
        );
        await pipelineInput.setValue(pipelineConfigurationFullPath);
        await waitForPromises();

        expect(invalidFeedback(pipelineInput.element)).toBe(message);
      },
    );
  });

  it.each`
    routeParams    | mutation
    ${{}}          | ${createComplianceFrameworkMutation}
    ${{ id: '1' }} | ${updateComplianceFrameworkMutation}
  `('invokes correct mutation', async ({ routeParams, mutation }) => {
    const stubHandlers = [
      [createComplianceFrameworkMutation, jest.fn()],
      [updateComplianceFrameworkMutation, jest.fn()],
    ];

    wrapper = createComponent(
      mountExtended,
      [[getComplianceFrameworkQuery, createComplianceFrameworksReportResponse], ...stubHandlers],
      routeParams,
    );
    await waitForPromises();

    const form = wrapper.find('form');
    await form.trigger('submit');

    expect(stubHandlers.find((handler) => handler[0] === mutation)[1]).toHaveBeenCalled();
  });

  describe('Delete button', () => {
    it('does not render delete button if creating new framework', async () => {
      wrapper = createComponent(shallowMountExtended, [], {});
      await waitForPromises();

      expect(findDeleteButton().exists()).toBe(false);
    });

    it('renders delete button if editing existing framework', async () => {
      wrapper = createComponent();
      await waitForPromises();

      expect(findDeleteButton().exists()).toBe(true);
    });

    it('clicking delete button invokes modal', async () => {
      wrapper = createComponent(shallowMountExtended);
      await waitForPromises();

      findDeleteButton().vm.$emit('click');

      expect(showDeleteModal).toHaveBeenCalled();
    });

    it('invokes delete process and navigates back on success removal', async () => {
      let resolveDeleteFrameworkMutation;
      const deleteFrameworkMutationFn = jest.fn().mockImplementation(
        () =>
          new Promise((resolve) => {
            resolveDeleteFrameworkMutation = resolve;
          }),
      );
      wrapper = createComponent(shallowMountExtended, [
        [
          getComplianceFrameworkQuery,
          () => ({ ...createComplianceFrameworksReportResponse(), default: true }),
        ],
        [deleteComplianceFrameworkMutation, deleteFrameworkMutationFn],
      ]);
      await waitForPromises();

      findDeleteModal().vm.$emit('delete');
      await waitForPromises();

      expect(deleteFrameworkMutationFn).toHaveBeenCalled();

      resolveDeleteFrameworkMutation({ data: { destroyComplianceFramework: { errors: [] } } });
      await waitForPromises();

      expect(routerBack).toHaveBeenCalled();
    });
  });
});

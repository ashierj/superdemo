import { GlDropdown, GlFormInput, GlSearchBoxByType } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import SidebarDropdown from '~/sidebar/components/sidebar_dropdown.vue';
import SidebarDropdownWidget from 'ee/sidebar/components/sidebar_dropdown_widget.vue';
import { IssuableAttributeType } from 'ee/sidebar/constants';
import { issuableAttributesQueries } from 'ee/sidebar/queries/constants';
import groupEpicsQuery from 'ee/sidebar/queries/group_epics.query.graphql';
import projectIssueEpicMutation from 'ee/sidebar/queries/project_issue_epic.mutation.graphql';
import updateWorkItemParent from 'ee/sidebar/queries/project_issue_update_parent.mutation.graphql';
import projectIssueEpicQuery from 'ee/sidebar/queries/project_issue_epic.query.graphql';
import workItemParent from 'ee/sidebar/queries/project_issue_parent.query.graphql';
import projectIssueEpicSubscription from 'ee/sidebar/queries/issuable_epic.subscription.graphql';
import workItemUpdateParentSubscription from 'ee/sidebar/queries/work_item_parent.subscription.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { TYPE_ISSUE } from '~/issues/constants';
import { WORK_ITEM_TYPE_VALUE_EPIC } from '~/work_items/constants';
import { clickEdit, search } from '../helpers';

import {
  mockIssue,
  mockGroupEpicsResponse,
  noCurrentEpicResponse,
  mockEpicMutationResponse,
  mockEpic2,
  emptyGroupEpicsResponse,
  mockNoPermissionEpicResponse,
  mockEpicUpdatesSubscriptionResponse,
  noParentUpdatedResponse,
  currentEpicHasParentResponse,
  mockWorkItemEpicMutationResponse,
  currentWorkItemEpicResponse,
  mockSetEpicNullMutationResponse,
  mockSetWorkItemEpicNullMutationResponse,
  mockGroupWorkItemEpicsResponse,
  currentEpicResponse,
} from '../mock_data';

jest.mock('~/alert');

describe('SidebarDropdownWidget', () => {
  let wrapper;
  let mockApollo;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findSidebarDropdown = () => wrapper.findComponent(SidebarDropdown);
  const findPopoverCta = () => wrapper.findByTestId('confirm-edit-cta');
  const findPopoverCancel = () => wrapper.findByTestId('confirm-edit-cancel');
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);

  const waitForDropdown = async () => {
    /** This sequence is important to wait for
     * dropdown to render
     */
    await waitForPromises();
    jest.runOnlyPendingTimers();
    await waitForPromises();
  };

  const createComponentWithApollo = async ({
    requestHandlers = [],
    groupEpicsSpy = jest.fn().mockResolvedValue(mockGroupEpicsResponse),
    currentEpicSpy = jest.fn().mockResolvedValue(noCurrentEpicResponse),
    epicUpdatedSpy = jest.fn().mockResolvedValue(mockEpicUpdatesSubscriptionResponse),
    parentUpdatedSpy = jest.fn().mockResolvedValue(noParentUpdatedResponse),
    showWorkItemEpics = false,
  } = {}) => {
    Vue.use(VueApollo);
    mockApollo = createMockApollo([
      [groupEpicsQuery, groupEpicsSpy],
      [projectIssueEpicQuery, currentEpicSpy],
      [projectIssueEpicSubscription, epicUpdatedSpy],
      [workItemUpdateParentSubscription, parentUpdatedSpy],
      ...requestHandlers,
    ]);

    wrapper = extendedWrapper(
      mount(SidebarDropdownWidget, {
        provide: {
          canUpdate: true,
          issuableAttributesQueries,
          glFeatures: {
            epicWidgetEditConfirmation: true,
          },
        },
        apolloProvider: mockApollo,
        propsData: {
          workspacePath: mockIssue.projectPath,
          attrWorkspacePath: mockIssue.groupPath,
          iid: mockIssue.iid,
          issuableType: TYPE_ISSUE,
          issuableAttribute: IssuableAttributeType.Epic,
          issueId: 'gid://gitlab/Issue/1',
          showWorkItemEpics,
        },
        attachTo: document.body,
      }),
    );

    jest.runOnlyPendingTimers();
    await waitForPromises();
  };

  describe('with mock apollo', () => {
    let error;

    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException');
      error = new Error('mayday');
    });

    describe("when issuable type is 'issue'", () => {
      describe('when dropdown is expanded and user can edit', () => {
        let epicMutationSpy;
        beforeEach(async () => {
          epicMutationSpy = jest.fn().mockResolvedValue(mockEpicMutationResponse);

          await createComponentWithApollo({
            requestHandlers: [[projectIssueEpicMutation, epicMutationSpy]],
          });

          await clickEdit(wrapper);
        });

        it('renders the dropdown on clicking edit', () => {
          expect(findDropdown().isVisible()).toBe(true);
        });

        it('focuses on the input when dropdown is shown', () => {
          expect(document.activeElement).toEqual(wrapper.findComponent(GlFormInput).element);
        });

        describe('when currentAttribute is not equal to attribute id', () => {
          describe('when update is successful', () => {
            beforeEach(() => {
              findSidebarDropdown().vm.$emit('change', { id: mockEpic2.id });
            });

            it('calls setIssueAttribute mutation', () => {
              expect(epicMutationSpy).toHaveBeenCalledWith({
                iid: mockIssue.iid,
                attributeId: mockEpic2.id,
                fullPath: mockIssue.projectPath,
              });
            });
          });
        });

        describe('epics', () => {
          let groupEpicsSpy;

          describe('when a user is searching epics', () => {
            const mockSearchTerm = 'foobar';

            beforeEach(async () => {
              groupEpicsSpy = jest.fn().mockResolvedValueOnce(emptyGroupEpicsResponse);
              await createComponentWithApollo({ groupEpicsSpy });

              await clickEdit(wrapper);
            });

            it('sends a groupEpics query with the entered search term "foo" and in TITLE param', async () => {
              await search(wrapper, mockSearchTerm);

              expect(groupEpicsSpy).toHaveBeenCalledWith({
                fullPath: mockIssue.groupPath,
                sort: 'TITLE_ASC',
                state: 'opened',
                title: mockSearchTerm,
                includeWorkItems: false,
                in: 'TITLE',
              });
            });
          });

          describe('when a user is not searching', () => {
            beforeEach(async () => {
              groupEpicsSpy = jest.fn().mockResolvedValueOnce(emptyGroupEpicsResponse);
              await createComponentWithApollo({ groupEpicsSpy });

              await clickEdit(wrapper);
            });

            it('sends a groupEpics query with empty title and undefined in param', async () => {
              await waitForPromises();

              // Account for debouncing
              jest.runAllTimers();

              expect(groupEpicsSpy).toHaveBeenCalledWith({
                fullPath: mockIssue.groupPath,
                includeWorkItems: false,
                sort: 'TITLE_ASC',
                state: 'opened',
              });
            });

            it('sends a groupEpics query for an IID with the entered search term "&1"', async () => {
              await search(wrapper, '&1');

              expect(groupEpicsSpy).toHaveBeenCalledWith({
                fullPath: mockIssue.groupPath,
                iidStartsWith: '1',
                sort: 'TITLE_ASC',
                includeWorkItems: false,
                state: 'opened',
              });
            });
          });
        });
      });

      describe('currentAttributes', () => {
        it('should call createAlert if currentAttributes query fails', async () => {
          await createComponentWithApollo({
            currentEpicSpy: jest.fn().mockRejectedValue(error),
          });

          expect(createAlert).toHaveBeenCalledWith({
            message: 'An error occurred while fetching the assigned epic of the selected issue.',
            captureError: true,
            error: expect.any(Error),
          });
        });
      });

      describe("when attribute type is 'epic'", () => {
        describe('real-time epic link updates', () => {
          it('should submit GraphQL subscription', async () => {
            const epicUpdatedSpy = jest.fn().mockResolvedValue(mockEpicUpdatesSubscriptionResponse);
            await createComponentWithApollo({
              epicUpdatedSpy,
            });

            expect(epicUpdatedSpy).toHaveBeenCalled();
          });
        });

        describe("when user doesn't have permission", () => {
          it('opens popover on edit click', async () => {
            await createComponentWithApollo({
              currentEpicSpy: jest.fn().mockResolvedValue(mockNoPermissionEpicResponse),
            });

            const spy = jest.spyOn(wrapper.vm.$children[0].$refs.popover, '$emit');

            await clickEdit(wrapper);

            expect(spy).toHaveBeenCalledWith('open');

            spy.mockRestore();
          });

          it('renders dropdown when popover is confirmed', async () => {
            await createComponentWithApollo({
              currentEpicSpy: jest.fn().mockResolvedValue(mockNoPermissionEpicResponse),
            });

            await clickEdit(wrapper);

            const button = findPopoverCta();
            button.trigger('click');
            await waitForDropdown();

            expect(findDropdown().isVisible()).toBe(true);
          });

          it('does not render dropdown when popover is canceled', async () => {
            await createComponentWithApollo({
              currentEpicSpy: jest.fn().mockResolvedValue(mockNoPermissionEpicResponse),
            });

            await clickEdit(wrapper);

            const button = findPopoverCancel();
            button.trigger('click');
            await waitForDropdown();

            expect(findDropdown().exists()).toBe(false);
          });
        });

        describe('showWorkItemEpics is true', () => {
          const currentEpicHasParentSpy = jest.fn().mockResolvedValue(currentEpicHasParentResponse);
          const currentEpicSpy = jest.fn().mockResolvedValue(currentEpicResponse);
          const currentWorkItemEpicSpy = jest.fn().mockResolvedValue(currentWorkItemEpicResponse);
          const setEpicNullMutationSpy = jest
            .fn()
            .mockResolvedValue(mockSetEpicNullMutationResponse);
          const epicMutationSpy = jest.fn().mockResolvedValue(mockEpicMutationResponse);
          const workItemEpicMutationSpy = jest
            .fn()
            .mockResolvedValue(mockWorkItemEpicMutationResponse);
          const setWorkItemEpicNullMutationSpy = jest
            .fn()
            .mockResolvedValue(mockSetWorkItemEpicNullMutationResponse);
          const groupWorkItemEpicsSpy = jest.fn().mockResolvedValue(mockGroupWorkItemEpicsResponse);

          it('search textbox is not displayed', async () => {
            await createComponentWithApollo({
              showWorkItemEpics: true,
            });

            await clickEdit(wrapper);
            expect(findSearchBox().exists()).toBe(false);
          });

          describe('when hasParent is true', () => {
            beforeEach(async () => {
              await createComponentWithApollo({
                showWorkItemEpics: true,
                currentEpicSpy: currentEpicHasParentSpy,
                groupEpicsSpy: groupWorkItemEpicsSpy,
                requestHandlers: [[workItemParent, currentWorkItemEpicSpy]],
              });

              await clickEdit(wrapper);
            });

            it('calls work item query to fetch current work item epic', () => {
              expect(currentEpicHasParentSpy).toHaveBeenCalled();
              expect(currentWorkItemEpicSpy).toHaveBeenCalled();
            });

            it('calls workItemUpdate and then setIssueAttribute mutation on selecting an epic', async () => {
              await createComponentWithApollo({
                showWorkItemEpics: true,
                currentEpicSpy: currentEpicHasParentSpy,
                requestHandlers: [
                  [projectIssueEpicMutation, epicMutationSpy],
                  [updateWorkItemParent, setWorkItemEpicNullMutationSpy],
                  [workItemParent, currentWorkItemEpicSpy],
                ],
              });

              findSidebarDropdown().vm.$emit('change', {
                id: 'gid://gitlab/Epic/2',
              });

              expect(setWorkItemEpicNullMutationSpy).toHaveBeenCalledWith({
                input: {
                  id: mockIssue.id,
                  hierarchyWidget: { parentId: null },
                },
              });

              await waitForPromises();

              expect(epicMutationSpy).toHaveBeenCalledWith({
                iid: mockIssue.iid,
                attributeId: 'gid://gitlab/Epic/2',
                fullPath: mockIssue.projectPath,
              });
            });

            it('calls workItemUpdate mutation on selecting a work item epic', async () => {
              await createComponentWithApollo({
                showWorkItemEpics: true,
                currentEpicSpy: currentEpicHasParentSpy,
                requestHandlers: [
                  [updateWorkItemParent, workItemEpicMutationSpy],
                  [workItemParent, currentWorkItemEpicSpy],
                ],
              });

              findSidebarDropdown().vm.$emit('change', {
                id: 'gid://gitlab/WorkItem/4',
                workItemType: { name: WORK_ITEM_TYPE_VALUE_EPIC },
              });

              expect(workItemEpicMutationSpy).toHaveBeenCalledWith({
                input: {
                  id: mockIssue.id,
                  hierarchyWidget: { parentId: null },
                },
              });

              await waitForPromises();

              expect(workItemEpicMutationSpy).toHaveBeenCalledWith({
                input: {
                  id: mockIssue.id,
                  hierarchyWidget: { parentId: 'gid://gitlab/WorkItem/4' },
                },
              });
            });
          });

          describe('when hasParent is false', () => {
            beforeEach(async () => {
              await createComponentWithApollo({
                showWorkItemEpics: true,
                currentEpicSpy,
                groupEpicsSpy: groupWorkItemEpicsSpy,
                requestHandlers: [[workItemParent, currentWorkItemEpicSpy]],
              });

              await clickEdit(wrapper);
            });

            it('does not call work item query', () => {
              expect(currentEpicSpy).toHaveBeenCalled();
              expect(currentWorkItemEpicSpy).not.toHaveBeenCalled();
            });

            it('calls setIssueAttribute and then work item mutation on selecting an work item epic', async () => {
              await createComponentWithApollo({
                showWorkItemEpics: true,
                currentEpicSpy,
                requestHandlers: [
                  [projectIssueEpicMutation, setEpicNullMutationSpy],
                  [updateWorkItemParent, workItemEpicMutationSpy],
                ],
              });

              findSidebarDropdown().vm.$emit('change', {
                id: 'gid://gitlab/WorkItem/4',
                workItemType: { name: WORK_ITEM_TYPE_VALUE_EPIC },
              });

              expect(setEpicNullMutationSpy).toHaveBeenCalledWith({
                iid: mockIssue.iid,
                attributeId: null,
                fullPath: mockIssue.projectPath,
              });

              await waitForPromises();

              expect(workItemEpicMutationSpy).toHaveBeenCalledWith({
                input: {
                  id: mockIssue.id,
                  hierarchyWidget: { parentId: 'gid://gitlab/WorkItem/4' },
                },
              });
            });
          });
        });
      });
    });
  });
});

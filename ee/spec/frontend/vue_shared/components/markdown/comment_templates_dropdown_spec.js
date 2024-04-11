import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CommentTemplatesDropdown from '~/vue_shared/components/markdown/comment_templates_dropdown.vue';
import savedRepliesQuery from 'ee/vue_shared/components/markdown/saved_replies.query.graphql';

let wrapper;
let savedRepliesResp;

function createResponse() {
  return {
    data: {
      group: {
        id: 'gid://gitlab/Group/2',
        savedReplies: {
          nodes: [
            {
              id: 'gid://gitlab/Groups::SavedReply/1',
              name: 'group saved reply',
              content: 'Group saved reply content',
              __typename: 'GroupsSavedReply',
            },
          ],
        },
        __typename: 'Group',
      },
      project: {
        id: 'gid://gitlab/Project/2',
        savedReplies: {
          nodes: [
            {
              id: 'gid://gitlab/Projects::SavedReply/1',
              name: 'project saved reply',
              content: 'Project saved reply content',
              __typename: 'ProjectsSavedReply',
            },
          ],
        },
        __typename: 'Project',
      },
      currentUser: {
        id: 'gid://gitlab/User/2',
        savedReplies: {
          nodes: [
            {
              id: 'gid://gitlab/Users::SavedReply/1',
              name: 'saved_reply_1',
              content: 'Saved Reply Content',
              __typename: 'SavedReply',
            },
          ],
        },
        __typename: 'CurrentUser',
      },
    },
  };
}

function createMockApolloProvider(response = createResponse()) {
  Vue.use(VueApollo);

  savedRepliesResp = jest.fn().mockResolvedValue(response);

  const requestHandlers = [[savedRepliesQuery, savedRepliesResp]];

  return createMockApollo(requestHandlers);
}

function createComponent(options = {}) {
  const { mockApollo } = options;

  document.body.dataset.groupFullPath = 'gitlab-org';

  return mountExtended(CommentTemplatesDropdown, {
    propsData: {
      newCommentTemplatePaths: [{ path: '/new', text: 'New' }],
    },
    apolloProvider: mockApollo,
  });
}

describe('EE comment templates dropdown', () => {
  afterEach(() => {
    delete document.body.dataset.groupFullPath;
    delete document.body.dataset.projectFullPath;
  });

  it('renders group and user comment templates', async () => {
    const mockApollo = createMockApolloProvider();
    wrapper = createComponent({ mockApollo });

    wrapper.find('.js-comment-template-toggle').trigger('click');

    await waitForPromises();

    const items = wrapper.findAll('li');

    expect(items).toHaveLength(4);
    expect(items.at(0).text()).toBe('User');
    expect(items.at(1).text()).toContain('saved_reply_1');
    expect(items.at(2).text()).toBe('Group');
    expect(items.at(3).text()).toContain('group saved reply');
  });

  it('renders project, group and user comment templates', async () => {
    document.body.dataset.projectFullPath = 'gitlab-org';

    const mockApollo = createMockApolloProvider();
    wrapper = createComponent({ mockApollo });

    wrapper.find('.js-comment-template-toggle').trigger('click');

    await waitForPromises();

    const items = wrapper.findAll('li');

    expect(items).toHaveLength(6);
    expect(items.at(0).text()).toBe('User');
    expect(items.at(1).text()).toContain('saved_reply_1');
    expect(items.at(2).text()).toBe('Project');
    expect(items.at(3).text()).toContain('project saved reply');
    expect(items.at(4).text()).toBe('Group');
    expect(items.at(5).text()).toContain('group saved reply');
  });
});

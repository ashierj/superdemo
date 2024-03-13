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
      newCommentTemplatePath: '/new',
    },
    apolloProvider: mockApollo,
  });
}

describe('EE comment templates dropdown', () => {
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
});

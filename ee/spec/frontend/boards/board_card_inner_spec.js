import { GlLabel } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import IssueCardWeight from 'ee/boards/components/issue_card_weight.vue';
import IssueHealthStatus from 'ee/related_items_tree/components/issue_health_status.vue';
import BoardCardInner from '~/boards/components/board_card_inner.vue';
import isShowingLabelsQuery from '~/graphql_shared/client/is_showing_labels.query.graphql';
import { TYPE_ISSUE } from '~/issues/constants';

Vue.use(VueApollo);

describe('Board card component', () => {
  let wrapper;
  let issue;
  let list;
  let store;

  const mockApollo = createMockApollo();

  const createComponent = ({ props = {}, isShowingLabels = true } = {}) => {
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: isShowingLabelsQuery,
      data: {
        isShowingLabels,
      },
    });

    wrapper = shallowMount(BoardCardInner, {
      store,
      apolloProvider: mockApollo,
      propsData: {
        list,
        item: issue,
        index: 0,
        ...props,
      },
      provide: {
        groupId: null,
        rootPath: '/',
        scopedLabelsAvailable: false,
        isEpicBoard: false,
        allowSubEpics: false,
        issuableType: TYPE_ISSUE,
        isGroupBoard: true,
        isApolloBoard: false,
      },
    });
  };

  beforeEach(() => {
    list = {
      id: 300,
      position: 0,
      title: 'Test',
      listType: 'label',
      label: {
        id: 5000,
        title: 'Testing',
        color: '#ff0000',
        description: 'testing;',
        textColor: 'white',
      },
    };

    issue = {
      title: 'Testing',
      id: 1,
      iid: 1,
      confidential: false,
      labels: [list.label],
      assignees: [],
      referencePath: '#1',
      webUrl: '/test/1',
      weight: 1,
      blocked: true,
      blockedByCount: 2,
      healthStatus: 'onTrack',
    };
  });

  describe('labels', () => {
    beforeEach(() => {
      const label1 = {
        id: 3,
        title: 'testing 123',
        color: '#000cff',
        textColor: 'white',
        description: 'test',
      };

      issue.labels = [...issue.labels, label1];
    });

    it.each`
      type              | title              | desc
      ${'GroupLabel'}   | ${'Group label'}   | ${'shows group labels on group boards'}
      ${'ProjectLabel'} | ${'Project label'} | ${'shows project labels on group boards'}
    `('$desc', ({ type, title }) => {
      issue.labels = [
        ...issue.labels,
        {
          id: 9001,
          type,
          title,
          color: '#000000',
        },
      ];

      createComponent({ props: { groupId: 1 } });

      expect(wrapper.findAllComponents(GlLabel)).toHaveLength(3);
      expect(wrapper.findComponent(GlLabel).props('title')).toContain(title);
    });

    it('shows no labels when the isShowingLabels is false', () => {
      createComponent({ isShowingLabels: false });

      expect(wrapper.findAll('.board-card-labels')).toHaveLength(0);
    });
  });

  describe('weight', () => {
    it('shows weight component', () => {
      createComponent();

      expect(wrapper.findComponent(IssueCardWeight).exists()).toBe(true);
    });
  });

  describe('health status', () => {
    it('shows healthStatus component', () => {
      createComponent();

      expect(wrapper.findComponent(IssueHealthStatus).props('healthStatus')).toBe('onTrack');
    });
  });
});

import { GlDrawer } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BoardContentSidebar from '~/boards/components/board_content_sidebar.vue';
import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';
import { TYPE_ISSUE } from '~/issues/constants';
import { rawIssue } from '../mock_data';

Vue.use(VueApollo);

describe('ee/BoardContentSidebar', () => {
  let wrapper;

  const mockSetActiveBoardItemResolver = jest.fn();
  const mockApollo = createMockApollo([], {
    Mutation: {
      setActiveBoardItem: mockSetActiveBoardItemResolver,
    },
  });

  const setPortalAnchorPoint = () => {
    const el = document.createElement('div');
    el.setAttribute('id', 'js-right-sidebar-portal');
    document.body.appendChild(el);
  };

  const createComponent = ({ issuable = rawIssue } = {}) => {
    setPortalAnchorPoint();

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: activeBoardItemQuery,
      data: {
        activeBoardItem: issuable,
      },
    });

    /*
      Dynamically imported components (in our case ee imports)
      aren't stubbed automatically when using shallow mount in VTU v1:
      https://github.com/vuejs/vue-test-utils/issues/1279.

      This requires us to use mount and additionally mock components.
    */
    wrapper = mount(BoardContentSidebar, {
      apolloProvider: mockApollo,
      provide: {
        canUpdate: true,
        rootPath: '/',
        groupId: 1,
        issuableType: TYPE_ISSUE,
        isGroupBoard: false,
        epicFeatureAvailable: true,
        iterationFeatureAvailable: true,
        weightFeatureAvailable: true,
        healthStatusFeatureAvailable: true,
      },
      stubs: {
        GlDrawer: stubComponent(GlDrawer, {
          template: `
            <div>
              <slot name="title"></slot>
              <slot name="header"></slot>
              <slot></slot>
            </div>`,
        }),
        BoardEditableItem: true,
        BoardSidebarTitle: true,
        BoardSidebarTimeTracker: true,
        SidebarLabelsWidget: true,
        SidebarAssigneesWidget: true,
        SidebarConfidentialityWidget: true,
        SidebarDateWidget: true,
        SidebarSubscriptionsWidget: true,
        SidebarWeightWidget: true,
        SidebarHealthStatusWidget: true,
        SidebarDropdownWidget: true,
        SidebarIterationWidget: true,
        SidebarTodoWidget: true,
        SidebarTimeTracker: true,
        MountingPortal: true,
      },
    });
  };

  describe('issue sidebar', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('matches the snapshot', () => {
      expect(wrapper.findComponent(GlDrawer).element).toMatchSnapshot();
    });
  });

  describe('incident sidebar', () => {
    beforeEach(async () => {
      createComponent({ issuable: { ...rawIssue, epic: null, type: 'INCIDENT' } });
      await waitForPromises();
    });

    it('matches the snapshot', () => {
      expect(wrapper.findComponent(GlDrawer).element).toMatchSnapshot();
    });
  });
});

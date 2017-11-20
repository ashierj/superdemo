/* eslint-disable one-var, quote-props, comma-dangle, space-before-function-paren */

import _ from 'underscore';
import Vue from 'vue';
import VueResource from 'vue-resource';
import Flash from '../flash';
import { __ } from '../locale';
import FilteredSearchBoards from './filtered_search_boards';
import eventHub from './eventhub';
import sidebarEventHub from '../sidebar/event_hub';
import './models/issue';
import './models/label';
import './models/list';
import './models/milestone';
import './models/project';
import './models/assignee';
import './stores/boards_store';
import './stores/modal_store';
import BoardService from './services/board_service';
import './mixins/modal_mixins';
import './mixins/sortable_default_options';
import './filters/due_date_filters';
import './components/board';
import './components/board_sidebar';
import './components/new_list_dropdown';
import './components/modal/index';
import '../vue_shared/vue_resource_interceptor';
import { convertPermissionToBoolean } from '../lib/utils/common_utils';

import './components/boards_selector';
import collapseIcon from './icons/fullscreen_collapse.svg';
import expandIcon from './icons/fullscreen_expand.svg';

Vue.use(VueResource);

$(() => {
  const $boardApp = document.getElementById('board-app');
  const Store = gl.issueBoards.BoardsStore;
  const ModalStore = gl.issueBoards.ModalStore;
  const issueBoardsContent = document.querySelector('.content-wrapper > .js-focus-mode-board');

  window.gl = window.gl || {};

  if (gl.IssueBoardsApp) {
    gl.IssueBoardsApp.$destroy(true);
  }

  Store.create();

  // hack to allow sidebar scripts like milestone_select manipulate the BoardsStore
  gl.issueBoards.boardStoreIssueSet = (...args) => Vue.set(Store.detail.issue, ...args);
  gl.issueBoards.boardStoreIssueDelete = (...args) => Vue.delete(Store.detail.issue, ...args);

  gl.IssueBoardsApp = new Vue({
    el: $boardApp,
    components: {
      'board': gl.issueBoards.Board,
      'board-sidebar': gl.issueBoards.BoardSidebar,
      'board-add-issues-modal': gl.issueBoards.IssuesModal,
    },
    data: {
      state: Store.state,
      loading: true,
      boardsEndpoint: $boardApp.dataset.boardsEndpoint,
      listsEndpoint: $boardApp.dataset.listsEndpoint,
      boardId: $boardApp.dataset.boardId,
      disabled: $boardApp.dataset.disabled === 'true',
      issueLinkBase: $boardApp.dataset.issueLinkBase,
      rootPath: $boardApp.dataset.rootPath,
      bulkUpdatePath: $boardApp.dataset.bulkUpdatePath,
      detailIssue: Store.detail,
      defaultAvatar: $boardApp.dataset.defaultAvatar,
    },
    computed: {
      detailIssueVisible () {
        return Object.keys(this.detailIssue.issue).length;
      },
    },
    created () {
      gl.boardService = new BoardService({
        boardsEndpoint: this.boardsEndpoint,
        listsEndpoint: this.listsEndpoint,
        bulkUpdatePath: this.bulkUpdatePath,
        boardId: this.boardId,
      });
      Store.rootPath = this.boardsEndpoint;

      eventHub.$on('updateTokens', this.updateTokens);
      eventHub.$on('newDetailIssue', this.updateDetailIssue);
      eventHub.$on('clearDetailIssue', this.clearDetailIssue);
      sidebarEventHub.$on('toggleSubscription', this.toggleSubscription);
    },
    beforeDestroy() {
      eventHub.$off('updateTokens', this.updateTokens);
      eventHub.$off('newDetailIssue', this.updateDetailIssue);
      eventHub.$off('clearDetailIssue', this.clearDetailIssue);
      sidebarEventHub.$off('toggleSubscription', this.toggleSubscription);
    },
    mounted () {
      this.filterManager = new FilteredSearchBoards(Store.filter, true, Store.cantEdit);
      this.filterManager.setup();

      Store.disabled = this.disabled;
      gl.boardService.all()
        .then(response => response.json())
        .then((resp) => {
          resp.forEach((board) => {
            const list = Store.addList(board, this.defaultAvatar);

            if (list.type === 'closed') {
              list.position = Infinity;
              list.label = { description: 'Shows all closed issues. Moving an issue to this list closes it' };
            } else if (list.type === 'backlog') {
              list.position = -1;
            }
          });

          this.state.lists = _.sortBy(this.state.lists, 'position');

          Store.addBlankState();
          Store.addPromotionState();
          this.loading = false;
        })
        .catch(() => new Flash('An error occurred. Please try again.'));
    },
    methods: {
      updateTokens() {
        this.filterManager.updateTokens();
      },
      updateDetailIssue(newIssue) {
        const sidebarInfoEndpoint = newIssue.sidebarInfoEndpoint;
        if (sidebarInfoEndpoint && newIssue.subscribed === undefined) {
          newIssue.setFetchingState('subscriptions', true);
          BoardService.getIssueInfo(sidebarInfoEndpoint)
            .then(res => res.json())
            .then((data) => {
              newIssue.setFetchingState('subscriptions', false);
              newIssue.updateData({
                subscribed: data.subscribed,
              });
            })
            .catch(() => {
              newIssue.setFetchingState('subscriptions', false);
              Flash(__('An error occurred while fetching sidebar data'));
            });
        }

        Store.detail.issue = newIssue;
      },
      clearDetailIssue() {
        Store.detail.issue = {};
      },
      toggleSubscription(id) {
        const issue = Store.detail.issue;
        if (issue.id === id && issue.toggleSubscriptionEndpoint) {
          issue.setFetchingState('subscriptions', true);
          BoardService.toggleIssueSubscription(issue.toggleSubscriptionEndpoint)
            .then(() => {
              issue.setFetchingState('subscriptions', false);
              issue.updateData({
                subscribed: !issue.subscribed,
              });
            })
            .catch(() => {
              issue.setFetchingState('subscriptions', false);
              Flash(__('An error occurred when toggling the notification subscription'));
            });
        }
      }
    },
  });

  gl.IssueBoardsSearch = new Vue({
    el: document.getElementById('js-add-list'),
    data: {
      filters: Store.state.filters,
      milestoneTitle: $boardApp.dataset.boardMilestoneTitle,
    },
    mounted () {
      gl.issueBoards.newListDropdownInit();
    },
  });

  const configEl = document.querySelector('.js-board-config');

  if (configEl) {
    gl.boardConfigToggle = new Vue({
      el: configEl,
      data() {
        return {
          canAdminList: convertPermissionToBoolean(
            this.$options.el.dataset.canAdminList,
          ),
        };
      },
      methods: {
        showPage: page => gl.issueBoards.BoardsStore.showPage(page),
      },
      computed: {
        buttonText() {
          return this.canAdminList ? 'Edit board' : 'View scope';
        },
      },
      template: `
        <div class="prepend-left-10">
          <button
            class="btn btn-inverted"
            type="button"
            @click.prevent="showPage('edit')"
          >
            {{ buttonText }}
          </button>
        </div>
      `,
    });
  }

  gl.IssueBoardsModalAddBtn = new Vue({
    mixins: [gl.issueBoards.ModalMixins],
    el: document.getElementById('js-add-issues-btn'),
    data() {
      return {
        modal: ModalStore.store,
        store: Store.state,
        isFullscreen: false,
        focusModeAvailable: convertPermissionToBoolean(
          $boardApp.dataset.focusModeAvailable,
        ),
        canAdminList: this.$options.el && convertPermissionToBoolean(
          this.$options.el.dataset.canAdminList,
        ),
      };
    },
    watch: {
      disabled() {
        this.updateTooltip();
      },
    },
    computed: {
      disabled() {
        if (!this.store) {
          return true;
        }
        return !this.store.lists.filter(list => !list.preset).length;
      },
      tooltipTitle() {
        if (this.disabled) {
          return 'Please add a list to your board first';
        }

        return '';
      },
    },
    methods: {
      updateTooltip() {
        const $tooltip = $(this.$refs.addIssuesButton);

        this.$nextTick(() => {
          if (this.disabled) {
            $tooltip.tooltip();
          } else {
            $tooltip.tooltip('destroy');
          }
        });
      },
      openModal() {
        if (!this.disabled) {
          this.toggleModal(true);
        }
      },
    },
    mounted() {
      this.updateTooltip();
    },
    template: `
      <div class="board-extra-actions">
        <button
          class="btn btn-create prepend-left-10"
          type="button"
          data-placement="bottom"
          ref="addIssuesButton"
          :class="{ 'disabled': disabled }"
          :title="tooltipTitle"
          :aria-disabled="disabled"
          v-if="canAdminList"
          @click="openModal">
          Add issues
        </button>
      </div>
    `,
  });

  gl.IssueBoardsToggleFocusBtn = new Vue({
    el: document.getElementById('js-toggle-focus-btn'),
    data: {
      modal: ModalStore.store,
      store: Store.state,
      isFullscreen: false,
      focusModeAvailable: convertPermissionToBoolean($boardApp.dataset.focusModeAvailable),
    },
    methods: {
      toggleFocusMode() {
        if (!this.focusModeAvailable) { return; }

        $(this.$refs.toggleFocusModeButton).tooltip('hide');
        issueBoardsContent.classList.toggle('is-focused');

        this.isFullscreen = !this.isFullscreen;
      },
    },
    template: `
      <div class="board-extra-actions">
        <a
          href="#"
          class="btn btn-default has-tooltip prepend-left-10 js-focus-mode-btn"
          role="button"
          aria-label="Toggle focus mode"
          title="Toggle focus mode"
          ref="toggleFocusModeButton"
          v-if="focusModeAvailable"
          @click="toggleFocusMode">
          <span v-show="isFullscreen">
            ${collapseIcon}
          </span>
          <span v-show="!isFullscreen">
            ${expandIcon}
          </span>
        </a>
      </div>
    `,
  });

  gl.IssueboardsSwitcher = new Vue({
    el: '#js-multiple-boards-switcher',
    components: {
      'boards-selector': gl.issueBoards.BoardsSelector,
    }
  });
});

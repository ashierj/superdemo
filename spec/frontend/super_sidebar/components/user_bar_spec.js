import { GlBadge } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import Vue, { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { __ } from '~/locale';
import CreateMenu from '~/super_sidebar/components/create_menu.vue';
import UserMenu from '~/super_sidebar/components/user_menu.vue';
import SearchModal from '~/super_sidebar/components/global_search/components/global_search.vue';
import SetStatusModal from '~/set_status_modal/set_status_modal_wrapper.vue';
import BrandLogo from 'jh_else_ce/super_sidebar/components/brand_logo.vue';
import MergeRequestMenu from '~/super_sidebar/components/merge_request_menu.vue';
import UserBar from '~/super_sidebar/components/user_bar.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import waitForPromises from 'helpers/wait_for_promises';
import { userCounts } from '~/super_sidebar/user_counts_manager';
import { stubComponent } from 'helpers/stub_component';
import {
  sidebarData as mockSidebarData,
  loggedOutSidebarData,
  userMenuMockStatus as mockStatus,
} from '../mock_data';
import { MOCK_DEFAULT_SEARCH_OPTIONS } from './global_search/mock_data';

describe('UserBar component', () => {
  let wrapper;

  const findCreateMenu = () => wrapper.findComponent(CreateMenu);
  const findUserMenu = () => wrapper.findComponent(UserMenu);
  const findIssuesCounter = () => wrapper.findByTestId('issues-shortcut-button');
  const findMRsCounter = () => wrapper.findByTestId('merge-requests-shortcut-button');
  const findTodosCounter = () => wrapper.findByTestId('todos-shortcut-button');
  const findMergeRequestMenu = () => wrapper.findComponent(MergeRequestMenu);
  const findBrandLogo = () => wrapper.findComponent(BrandLogo);
  const findCollapseButton = () => wrapper.findByTestId('super-sidebar-collapse-button');
  const findSearchButton = () => wrapper.findByTestId('super-sidebar-search-button');
  const findSearchModal = () => wrapper.findComponent(SearchModal);
  const findSetStatusModal = () => wrapper.findComponent(SetStatusModal);
  const findStopImpersonationButton = () => wrapper.findByTestId('stop-impersonation-btn');

  Vue.use(Vuex);

  const store = new Vuex.Store({
    getters: {
      searchOptions: () => MOCK_DEFAULT_SEARCH_OPTIONS,
    },
  });
  const createWrapper = ({
    hasCollapseButton = true,
    sidebarData = mockSidebarData,
    provideOverrides = {},
  } = {}) => {
    wrapper = shallowMountExtended(UserBar, {
      propsData: {
        hasCollapseButton,
        sidebarData,
      },
      stubs: {
        SetStatusModal: stubComponent(SetStatusModal),
      },
      provide: {
        isImpersonating: false,
        ...provideOverrides,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      store,
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    describe('"Create new..." menu', () => {
      describe('when there are no menu items for it', () => {
        // This scenario usually happens for an "External" user.
        it('does not render it', () => {
          createWrapper({ sidebarData: { ...mockSidebarData, create_new_menu_groups: [] } });
          expect(findCreateMenu().exists()).toBe(false);
        });
      });

      describe('when there are menu items for it', () => {
        it('passes the "Create new..." menu groups to the create-menu component', () => {
          expect(findCreateMenu().props('groups')).toBe(mockSidebarData.create_new_menu_groups);
        });
      });
    });

    it('passes the "Merge request" menu groups to the merge_request_menu component', () => {
      expect(findMergeRequestMenu().props('items')).toBe(mockSidebarData.merge_request_menu);
    });

    it('renders issues counter', () => {
      const isuesCounter = findIssuesCounter();
      expect(isuesCounter.props('count')).toBe(userCounts.assigned_issues);
      expect(isuesCounter.props('href')).toBe(mockSidebarData.issues_dashboard_path);
      expect(isuesCounter.props('label')).toBe(__('Issues'));
      expect(isuesCounter.attributes('data-track-action')).toBe('click_link');
      expect(isuesCounter.attributes('data-track-label')).toBe('issues_link');
      expect(isuesCounter.attributes('data-track-property')).toBe('nav_core_menu');
      expect(isuesCounter.attributes('class')).toContain('dashboard-shortcuts-issues');
    });

    it('renders merge requests counter', () => {
      const mrsCounter = findMRsCounter();
      expect(mrsCounter.props('count')).toBe(
        userCounts.assigned_merge_requests + userCounts.review_requested_merge_requests,
      );
      expect(mrsCounter.props('label')).toBe(__('Merge requests'));
      expect(mrsCounter.attributes('data-track-action')).toBe('click_dropdown');
      expect(mrsCounter.attributes('data-track-label')).toBe('merge_requests_menu');
      expect(mrsCounter.attributes('data-track-property')).toBe('nav_core_menu');
    });

    describe('Todos counter', () => {
      it('renders it', () => {
        const todosCounter = findTodosCounter();
        expect(todosCounter.props('href')).toBe(mockSidebarData.todos_dashboard_path);
        expect(todosCounter.props('label')).toBe(__('To-Do list'));
        expect(todosCounter.attributes('data-track-action')).toBe('click_link');
        expect(todosCounter.attributes('data-track-label')).toBe('todos_link');
        expect(todosCounter.attributes('data-track-property')).toBe('nav_core_menu');
        expect(todosCounter.attributes('class')).toContain('shortcuts-todos');
      });

      it('should update todo counter when event is emitted', async () => {
        createWrapper();
        const count = 100;
        document.dispatchEvent(new CustomEvent('todo:toggle', { detail: { count } }));
        await nextTick();
        expect(findTodosCounter().props('count')).toBe(count);
      });
    });

    it('renders branding logo', () => {
      expect(findBrandLogo().exists()).toBe(true);
      expect(findBrandLogo().props('logoUrl')).toBe(mockSidebarData.logo_url);
    });

    it('does not render the "Stop impersonating" button', () => {
      expect(findStopImpersonationButton().exists()).toBe(false);
    });

    it('renders collapse button when hasCollapseButton is true', () => {
      expect(findCollapseButton().exists()).toBe(true);
    });

    it('does not render collapse button when hasCollapseButton is false', () => {
      createWrapper({ hasCollapseButton: false });
      expect(findCollapseButton().exists()).toBe(false);
    });
  });

  describe('GitLab Next badge', () => {
    describe('when on canary', () => {
      it('should render a badge to switch off GitLab Next', () => {
        createWrapper({ sidebarData: { ...mockSidebarData, gitlab_com_and_canary: true } });
        const badge = wrapper.findComponent(GlBadge);
        expect(badge.text()).toBe('Next');
        expect(badge.attributes('href')).toBe(mockSidebarData.canary_toggle_com_url);
      });
    });

    describe('when not on canary', () => {
      it('should not render the GitLab Next badge', () => {
        createWrapper({ sidebarData: { ...mockSidebarData, gitlab_com_and_canary: false } });
        const badge = wrapper.findComponent(GlBadge);
        expect(badge.exists()).toBe(false);
      });
    });
  });

  describe('set status modal', () => {
    describe('when there is no status data', () => {
      it('should not render the modal', () => {
        createWrapper({ sidebarData: { ...mockSidebarData, status: null } });

        expect(findSetStatusModal().exists()).toBe(false);
      });
    });

    describe('when the user cannot update the status', () => {
      it('should not render the modal', () => {
        createWrapper({
          sidebarData: { ...mockSidebarData, status: { ...mockStatus, can_update: false } },
        });

        expect(findSetStatusModal().exists()).toBe(false);
      });
    });

    describe('when the user can update the status', () => {
      describe('and the status is busy or customized', () => {
        it.each`
          busy     | customized
          ${true}  | ${true}
          ${true}  | ${false}
          ${false} | ${true}
        `('should pass the current status to the modal', ({ busy, customized }) => {
          createWrapper({
            sidebarData: {
              ...mockSidebarData,
              status: { ...mockStatus, can_update: true, busy, customized },
            },
          });

          expect(findSetStatusModal().exists()).toBe(true);
          expect(findSetStatusModal().props()).toMatchObject({
            defaultEmoji: 'speech_balloon',
            currentEmoji: mockStatus.emoji,
            currentMessage: mockStatus.message,
            currentAvailability: mockStatus.availability,
            currentClearStatusAfter: mockStatus.clear_after,
          });
        });
      });

      describe('and the status is neither busy nor customized', () => {
        it('should pass an empty status to the modal', () => {
          createWrapper({
            sidebarData: {
              ...mockSidebarData,
              status: { ...mockStatus, can_update: true, busy: false, customized: false },
            },
          });

          expect(findSetStatusModal().exists()).toBe(true);
          expect(findSetStatusModal().props()).toMatchObject({
            defaultEmoji: 'speech_balloon',
            currentEmoji: '',
            currentMessage: '',
          });
        });
      });
    });
  });

  describe('Search', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('should render search button', () => {
      expect(findSearchButton().exists()).toBe(true);
    });

    it('search button should have tooltip', () => {
      const tooltip = getBinding(findSearchButton().element, 'gl-tooltip');
      expect(tooltip.value).toBe(`Type <kbd>/</kbd> to search`);
    });

    it('should render search modal', () => {
      expect(findSearchModal().exists()).toBe(true);
    });

    describe('Search tooltip', () => {
      it('should hide search tooltip when modal is shown', async () => {
        findSearchModal().vm.$emit('shown');
        await nextTick();
        const tooltip = getBinding(findSearchButton().element, 'gl-tooltip');
        expect(tooltip.value).toBe('');
      });

      it('should add search tooltip when modal is hidden', async () => {
        findSearchModal().vm.$emit('hidden');
        await nextTick();
        const tooltip = getBinding(findSearchButton().element, 'gl-tooltip');
        expect(tooltip.value).toBe(`Type <kbd>/</kbd> to search`);
      });
    });
  });

  describe('While impersonating a user', () => {
    beforeEach(() => {
      createWrapper({ provideOverrides: { isImpersonating: true } });
    });

    it('renders the "Stop impersonating" button', () => {
      expect(findStopImpersonationButton().exists()).toBe(true);
    });

    it('sets the correct label on the button', () => {
      const btn = findStopImpersonationButton();
      const label = __('Stop impersonating');

      expect(btn.attributes('title')).toBe(label);
      expect(btn.attributes('aria-label')).toBe(label);
    });

    it('sets the href and data-method attributes', () => {
      const btn = findStopImpersonationButton();

      expect(btn.attributes('href')).toBe(mockSidebarData.stop_impersonation_path);
      expect(btn.attributes('data-method')).toBe('delete');
    });
  });

  describe('Logged out', () => {
    beforeEach(() => {
      createWrapper({ sidebarData: loggedOutSidebarData, gitlab_com_and_canary: true });
    });

    it('does not render brand logo', () => {
      expect(findBrandLogo().exists()).toBe(false);
    });

    it('does not render Next badge', () => {
      expect(wrapper.findComponent(GlBadge).exists()).toBe(false);
    });

    it('does not render create menu', () => {
      expect(findCreateMenu().exists()).toBe(false);
    });

    it('does not render user menu', () => {
      expect(findUserMenu().exists()).toBe(false);
    });

    it('does not render set status modal menu', () => {
      expect(findSetStatusModal().exists()).toBe(false);
    });

    it('does not render counters', () => {
      expect(findIssuesCounter().exists()).toBe(false);
      expect(findMRsCounter().exists()).toBe(false);
      expect(findTodosCounter().exists()).toBe(false);
    });
  });
});

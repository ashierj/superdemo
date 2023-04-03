import { GlBadge } from '@gitlab/ui';
import Vuex from 'vuex';
import Vue from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { __ } from '~/locale';
import CreateMenu from '~/super_sidebar/components/create_menu.vue';
import SearchModal from '~/super_sidebar/components/global_search/components/global_search.vue';
import MergeRequestMenu from '~/super_sidebar/components/merge_request_menu.vue';
import Counter from '~/super_sidebar/components/counter.vue';
import UserBar from '~/super_sidebar/components/user_bar.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import waitForPromises from 'helpers/wait_for_promises';
import { sidebarData } from '../mock_data';
import { MOCK_DEFAULT_SEARCH_OPTIONS } from './global_search/mock_data';

describe('UserBar component', () => {
  let wrapper;

  const findCreateMenu = () => wrapper.findComponent(CreateMenu);
  const findCounter = (at) => wrapper.findAllComponents(Counter).at(at);
  const findMergeRequestMenu = () => wrapper.findComponent(MergeRequestMenu);
  const findBrandLogo = () => wrapper.findByTestId('brand-header-custom-logo');
  const findSearchButton = () => wrapper.findByTestId('super-sidebar-search-button');
  const findSearchModal = () => wrapper.findComponent(SearchModal);

  Vue.use(Vuex);

  const store = new Vuex.Store({
    getters: {
      searchOptions: () => MOCK_DEFAULT_SEARCH_OPTIONS,
    },
  });
  const createWrapper = (extraSidebarData = {}) => {
    wrapper = shallowMountExtended(UserBar, {
      propsData: {
        sidebarData: { ...sidebarData, ...extraSidebarData },
      },
      provide: {
        rootPath: '/',
        toggleNewNavEndpoint: '/-/profile/preferences',
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

    it('passes the "Create new..." menu groups to the create-menu component', () => {
      expect(findCreateMenu().props('groups')).toBe(sidebarData.create_new_menu_groups);
    });

    it('passes the "Merge request" menu groups to the merge_request_menu component', () => {
      expect(findMergeRequestMenu().props('items')).toBe(sidebarData.merge_request_menu);
    });

    it('renders issues counter', () => {
      expect(findCounter(0).props('count')).toBe(sidebarData.assigned_open_issues_count);
      expect(findCounter(0).props('href')).toBe(sidebarData.issues_dashboard_path);
      expect(findCounter(0).props('label')).toBe(__('Issues'));
    });

    it('renders merge requests counter', () => {
      expect(findCounter(1).props('count')).toBe(sidebarData.total_merge_requests_count);
      expect(findCounter(1).props('label')).toBe(__('Merge requests'));
    });

    it('renders todos counter', () => {
      expect(findCounter(2).props('count')).toBe(sidebarData.todos_pending_count);
      expect(findCounter(2).props('href')).toBe('/dashboard/todos');
      expect(findCounter(2).props('label')).toBe(__('To-Do list'));
    });

    it('renders branding logo', () => {
      expect(findBrandLogo().exists()).toBe(true);
      expect(findBrandLogo().attributes('src')).toBe(sidebarData.logo_url);
    });
  });

  describe('GitLab Next badge', () => {
    describe('when on canary', () => {
      it('should render a badge to switch off GitLab Next', () => {
        createWrapper({ gitlab_com_and_canary: true });
        const badge = wrapper.findComponent(GlBadge);
        expect(badge.text()).toBe('Next');
        expect(badge.attributes('href')).toBe(sidebarData.canary_toggle_com_url);
      });
    });

    describe('when not on canary', () => {
      it('should not render the GitLab Next badge', () => {
        createWrapper({ gitlab_com_and_canary: false });
        const badge = wrapper.findComponent(GlBadge);
        expect(badge.exists()).toBe(false);
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
      expect(tooltip.value).toBe(`Search GitLab <kbd>/</kbd>`);
    });

    it('should render search modal', async () => {
      expect(findSearchModal().exists()).toBe(true);
    });
  });
});

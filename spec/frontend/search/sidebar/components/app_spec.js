import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import GlobalSearchSidebar from '~/search/sidebar/components/app.vue';
import ResultsFilters from '~/search/sidebar/components/results_filters.vue';
import ScopeNavigation from '~/search/sidebar/components/scope_navigation.vue';
import LanguageFilter from '~/search/sidebar/components/language_filter.vue';

Vue.use(Vuex);

describe('GlobalSearchSidebar', () => {
  let wrapper;

  const actionSpies = {
    applyQuery: jest.fn(),
    resetQuery: jest.fn(),
  };

  const createComponent = (initialState, featureFlags) => {
    const store = new Vuex.Store({
      state: {
        urlQuery: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
    });

    wrapper = shallowMount(GlobalSearchSidebar, {
      store,
      provide: {
        glFeatures: {
          ...featureFlags,
        },
      },
    });
  };

  const findSidebarSection = () => wrapper.find('section');
  const findFilters = () => wrapper.findComponent(ResultsFilters);
  const findSidebarNavigation = () => wrapper.findComponent(ScopeNavigation);
  const findLanguageAggregation = () => wrapper.findComponent(LanguageFilter);

  describe('renders properly', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent({});
      });
      it(`shows section`, () => {
        expect(findSidebarSection().exists()).toBe(true);
      });
    });

    describe.each`
      scope               | showFilters | ShowsLanguage
      ${'issues'}         | ${true}     | ${false}
      ${'merge_requests'} | ${true}     | ${false}
      ${'projects'}       | ${false}    | ${false}
      ${'blobs'}          | ${false}    | ${true}
    `('sidebar scope: $scope', ({ scope, showFilters, ShowsLanguage }) => {
      beforeEach(() => {
        createComponent(
          { urlQuery: { scope } },
          { searchBlobsLanguageAggregation: true, searchPageVerticalNav: true },
        );
      });

      it(`${!showFilters ? "doesn't" : ''} shows filters`, () => {
        expect(findFilters().exists()).toBe(showFilters);
      });

      it(`${!ShowsLanguage ? "doesn't" : ''} shows language filters`, () => {
        expect(findLanguageAggregation().exists()).toBe(ShowsLanguage);
      });
    });

    describe('renders navigation', () => {
      beforeEach(() => {
        createComponent({});
      });
      it('shows the vertical navigation', () => {
        expect(findSidebarNavigation().exists()).toBe(true);
      });
    });
  });

  describe('when search_blobs_language_aggregation is enabled', () => {
    beforeEach(() => {
      createComponent({ urlQuery: { scope: 'blobs' } }, { searchBlobsLanguageAggregation: true });
    });
    it('shows the language filter', () => {
      expect(findLanguageAggregation().exists()).toBe(true);
    });
  });

  describe('when search_blobs_language_aggregation is disabled', () => {
    beforeEach(() => {
      createComponent({ urlQuery: { scope: 'blobs' } }, { searchBlobsLanguageAggregation: false });
    });
    it('hides the language filter', () => {
      expect(findLanguageAggregation().exists()).toBe(false);
    });
  });
});

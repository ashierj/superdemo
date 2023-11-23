import { shallowMount } from '@vue/test-utils';
import { GlFilteredSearch } from '@gitlab/ui';
import GroupDependenciesFilteredSearch from 'ee/dependencies/components/filtered_search/group_dependencies_filtered_search.vue';
import LicenseToken from 'ee/dependencies/components/filtered_search/tokens/license_token.vue';
import ProjectToken from 'ee/dependencies/components/filtered_search/tokens/project_token.vue';
import createStore from 'ee/dependencies/store';

describe('GroupDependenciesFilteredSearch', () => {
  let wrapper;
  let store;

  const createVuexStore = () => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation();
  };

  const createComponent = () => {
    wrapper = shallowMount(GroupDependenciesFilteredSearch, { store });
  };

  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);

  beforeEach(() => {
    createVuexStore();
    createComponent();
  });

  describe('search input', () => {
    it('displays the correct placeholder', () => {
      expect(findFilteredSearch().props('placeholder')).toBe('Search or filter dependencies...');
    });

    it.each`
      tokenTitle   | tokenConfig
      ${'License'} | ${{ title: 'License', type: 'licenses', multiSelect: true, token: LicenseToken }}
      ${'Project'} | ${{ title: 'Project', type: 'project_ids', multiSelect: true, token: ProjectToken }}
    `('contains a "$tokenTitle" search token', ({ tokenConfig }) => {
      expect(findFilteredSearch().props('availableTokens')).toMatchObject(
        expect.arrayContaining([
          expect.objectContaining({
            ...tokenConfig,
          }),
        ]),
      );
    });
  });

  describe('submit', () => {
    it('dispatches the "fetchDependencies" Vuex action', () => {
      expect(store.dispatch).not.toHaveBeenCalled();

      const filterPayload = [{ type: 'license', value: { data: ['MIT'] } }];
      findFilteredSearch().vm.$emit('submit', filterPayload);

      expect(store.dispatch).toHaveBeenCalledWith('allDependencies/fetchDependencies', undefined);
    });
  });
});

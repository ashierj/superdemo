import { nextTick } from 'vue';
import {
  GlFilteredSearchSuggestion,
  GlFilteredSearchToken,
  GlIcon,
  GlLoadingIcon,
  GlIntersperse,
} from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import { trimText } from 'helpers/text_helper';
import createStore from 'ee/dependencies/store';
import LicenseToken from 'ee/dependencies/components/filtered_search/tokens/license_token.vue';
import waitForPromises from 'helpers/wait_for_promises';

const TEST_GROUP_LICENSES_ENDPOINT = 'https://gitlab.com/api/v4/group/123/-/licenses';
const TEST_LICENSES = [
  {
    name: 'Apache 2.0',
    spdx_identifier: 'Apache-2.0',
  },
  {
    name: 'MIT License',
    spdx_identifier: 'MIT',
  },
];

describe('ee/dependencies/components/filtered_search/tokens/license_token.vue', () => {
  let wrapper;
  let store;

  const createVuexStore = () => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation();
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(LicenseToken, {
      store,
      propsData: {
        config: {
          multiSelect: true,
        },
        value: {},
        active: false,
        ...propsData,
      },
      provide: {
        licensesEndpoint: TEST_GROUP_LICENSES_ENDPOINT,
      },
      stubs: {
        GlFilteredSearchToken: stubComponent(GlFilteredSearchToken, {
          template: `<div><slot name="view"></slot><slot name="suggestions"></slot></div>`,
        }),
        GlIntersperse,
      },
    });
  };

  beforeEach(() => {
    createVuexStore();
  });

  const findFilteredSearchToken = () => wrapper.findComponent(GlFilteredSearchToken);
  const isLoadingSuggestions = () => wrapper.findComponent(GlLoadingIcon).exists();
  const selectLicense = (license) => {
    findFilteredSearchToken().vm.$emit('select', license.name);
    return nextTick();
  };
  const searchForLicense = (searchTerm = '') => {
    findFilteredSearchToken().vm.$emit('input', { data: searchTerm });
    return waitForPromises();
  };

  describe('when the component is initially rendered', () => {
    it('shows a loading indicator while fetching the list of licenses', () => {
      store.state.allDependencies.fetchingLicensesInProgress = true;
      createComponent();

      expect(isLoadingSuggestions()).toBe(true);
    });

    it('fetches the list of licenses from the correct endpoint', () => {
      createComponent();

      expect(store.dispatch).toHaveBeenCalledWith(
        'allDependencies/fetchLicenses',
        TEST_GROUP_LICENSES_ENDPOINT,
      );
    });

    it('shows the full list of licenses once the fetch is completed', () => {
      store.state.allDependencies.licenses = TEST_LICENSES;
      createComponent();

      expect(wrapper.text()).toContain(TEST_LICENSES[0].name);
      expect(wrapper.text()).toContain(TEST_LICENSES[1].name);
    });

    it.each([
      { active: true, expectedValue: null },
      { active: false, expectedValue: { data: [] } },
    ])(
      'passes "$expectedValue" to the search-token when the dropdown is open: "$active"',
      ({ active, expectedValue }) => {
        createComponent({
          propsData: {
            active,
            value: { data: [] },
          },
        });

        expect(findFilteredSearchToken().props('value')).toEqual(
          expect.objectContaining(expectedValue),
        );
      },
    );
  });

  describe('once the licenses have been fetched', () => {
    beforeEach(() => {
      store.state.allDependencies.licenses = TEST_LICENSES;
      createComponent();
    });

    describe('when a user enters a search term', () => {
      it('shows the filtered list of suggestions', async () => {
        await searchForLicense(TEST_LICENSES[0].name);

        expect(wrapper.text()).toContain(TEST_LICENSES[0].name);
        expect(wrapper.text()).not.toContain(TEST_LICENSES[1].name);
      });
    });

    describe('when a user selects licenses to be filtered', () => {
      beforeEach(async () => {
        await searchForLicense();
      });

      it('displays a check-icon next to the selected license', async () => {
        const findFirstSearchSuggestionIcon = () =>
          wrapper.findAllComponents(GlFilteredSearchSuggestion).at(0).findComponent(GlIcon);
        const hiddenClassName = 'gl-visibility-hidden';

        expect(findFirstSearchSuggestionIcon().classes()).toContain(hiddenClassName);

        await selectLicense(TEST_LICENSES[0]);

        expect(findFirstSearchSuggestionIcon().classes()).not.toContain(hiddenClassName);
      });

      it('shows a comma seperated list of selected licenses', async () => {
        await selectLicense(TEST_LICENSES[0]);
        await selectLicense(TEST_LICENSES[1]);

        expect(trimText(wrapper.findByTestId('selected-licenses').text())).toBe(
          `${TEST_LICENSES[0].name}, ${TEST_LICENSES[1].name}`,
        );
      });
    });
  });
});

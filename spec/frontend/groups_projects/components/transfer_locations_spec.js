import {
  GlDropdown,
  GlDropdownItem,
  GlAlert,
  GlSearchBoxByType,
  GlIntersectionObserver,
  GlLoadingIcon,
} from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import currentUserNamespaceQueryResponse from 'test_fixtures/graphql/projects/settings/current_user_namespace.query.graphql.json';
import transferLocationsResponsePage1 from 'test_fixtures/api/projects/transfer_locations_page_1.json';
import transferLocationsResponsePage2 from 'test_fixtures/api/projects/transfer_locations_page_2.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import TransferLocations from '~/groups_projects/components/transfer_locations.vue';
import { getTransferLocations } from '~/api/projects_api';
import currentUserNamespaceQuery from '~/projects/settings/graphql/queries/current_user_namespace.query.graphql';

jest.mock('~/api/projects_api', () => ({
  getTransferLocations: jest.fn(),
}));

describe('TransferLocations', () => {
  let wrapper;

  // Default data
  const resourceId = '1';
  const defaultPropsData = {
    groupTransferLocationsApiMethod: getTransferLocations,
    value: null,
  };

  // Mock requests
  const defaultQueryHandler = jest.fn().mockResolvedValue(currentUserNamespaceQueryResponse);
  const mockResolvedGetTransferLocations = ({
    data = transferLocationsResponsePage1,
    page = '1',
    nextPage = '2',
    total = '4',
    totalPages = '2',
    prevPage = null,
  } = {}) => {
    getTransferLocations.mockResolvedValueOnce({
      data,
      headers: {
        'x-per-page': '2',
        'x-page': page,
        'x-total': total,
        'x-total-pages': totalPages,
        'x-next-page': nextPage,
        'x-prev-page': prevPage,
      },
    });
  };
  const mockRejectedGetTransferLocations = () => {
    const error = new Error();

    getTransferLocations.mockRejectedValueOnce(error);
  };

  // VTU wrapper helpers
  Vue.use(VueApollo);
  const createComponent = ({
    propsData = {},
    requestHandlers = [[currentUserNamespaceQuery, defaultQueryHandler]],
  } = {}) => {
    wrapper = mountExtended(TransferLocations, {
      provide: {
        resourceId,
      },
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      apolloProvider: createMockApollo(requestHandlers),
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const showDropdown = async () => {
    findDropdown().vm.$emit('show');
    await waitForPromises();
  };
  const findUserTransferLocations = () =>
    wrapper
      .findByTestId('user-transfer-locations')
      .findAllComponents(GlDropdownItem)
      .wrappers.map((dropdownItem) => dropdownItem.text());
  const findGroupTransferLocations = () =>
    wrapper
      .findByTestId('group-transfer-locations')
      .findAllComponents(GlDropdownItem)
      .wrappers.map((dropdownItem) => dropdownItem.text());
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findSearch = () => wrapper.findComponent(GlSearchBoxByType);
  const searchEmitInput = () => findSearch().vm.$emit('input', 'foo');
  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const intersectionObserverEmitAppear = () => findIntersectionObserver().vm.$emit('appear');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when `GlDropdown` is opened', () => {
    it('fetches and renders user and group transfer locations', async () => {
      mockResolvedGetTransferLocations();
      createComponent();
      await showDropdown();

      const { namespace } = currentUserNamespaceQueryResponse.data.currentUser;

      expect(findUserTransferLocations()).toEqual([namespace.fullName]);
      expect(findGroupTransferLocations()).toEqual(
        transferLocationsResponsePage1.map((transferLocation) => transferLocation.full_name),
      );
    });

    describe('when transfer locations have already been fetched', () => {
      beforeEach(async () => {
        mockResolvedGetTransferLocations();
        createComponent();
        await showDropdown();
      });

      it('does not fetch transfer locations', async () => {
        getTransferLocations.mockClear();
        defaultQueryHandler.mockClear();

        await showDropdown();

        expect(getTransferLocations).not.toHaveBeenCalled();
        expect(defaultQueryHandler).not.toHaveBeenCalled();
      });
    });

    describe('when `getTransferLocations` API call fails', () => {
      it('displays dismissible error alert', async () => {
        mockRejectedGetTransferLocations();
        createComponent();
        await showDropdown();

        const alert = findAlert();

        expect(alert.exists()).toBe(true);

        alert.vm.$emit('dismiss');
        await nextTick();

        expect(alert.exists()).toBe(false);
      });
    });

    describe('when `currentUser` GraphQL query fails', () => {
      it('displays error alert', async () => {
        mockResolvedGetTransferLocations();
        const error = new Error();
        createComponent({
          requestHandlers: [[currentUserNamespaceQuery, jest.fn().mockRejectedValueOnce(error)]],
        });
        await showDropdown();

        expect(findAlert().exists()).toBe(true);
      });
    });
  });

  describe('when transfer location is selected', () => {
    it('displays transfer location as selected', () => {
      const [{ id, full_name: humanName }] = transferLocationsResponsePage1;

      createComponent({
        propsData: {
          value: {
            id,
            humanName,
          },
        },
      });

      expect(findDropdown().props('text')).toBe(humanName);
    });
  });

  describe('when search is typed in', () => {
    const transferLocationsResponseSearch = [transferLocationsResponsePage1[0]];

    const arrange = async () => {
      mockResolvedGetTransferLocations();
      createComponent();
      await showDropdown();
      mockResolvedGetTransferLocations({ data: transferLocationsResponseSearch });
      searchEmitInput();
      await nextTick();
    };

    it('sets `isSearchLoading` prop to `true`', async () => {
      await arrange();

      expect(findSearch().props('isLoading')).toBe(true);
    });

    it('passes `search` param to API call and updates group transfer locations', async () => {
      await arrange();

      await waitForPromises();

      expect(getTransferLocations).toHaveBeenCalledWith(
        resourceId,
        expect.objectContaining({ search: 'foo' }),
      );
      expect(findGroupTransferLocations()).toEqual(
        transferLocationsResponseSearch.map((transferLocation) => transferLocation.full_name),
      );
    });
  });

  describe('when there are no more pages', () => {
    it('does not show intersection observer', async () => {
      mockResolvedGetTransferLocations({
        data: transferLocationsResponsePage1,
        nextPage: null,
        total: '2',
        totalPages: '1',
        prevPage: null,
      });
      createComponent();
      await showDropdown();

      expect(findIntersectionObserver().exists()).toBe(false);
    });
  });

  describe('when intersection observer appears', () => {
    const arrange = async () => {
      mockResolvedGetTransferLocations();
      createComponent();
      await showDropdown();

      mockResolvedGetTransferLocations({
        data: transferLocationsResponsePage2,
        page: '2',
        nextPage: null,
        prevPage: '1',
        totalPages: '2',
      });

      intersectionObserverEmitAppear();
      await nextTick();
    };

    it('shows loading icon', async () => {
      await arrange();

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('passes `page` param to API call', async () => {
      await arrange();

      await waitForPromises();

      expect(getTransferLocations).toHaveBeenCalledWith(
        resourceId,
        expect.objectContaining({ page: 2 }),
      );
    });

    it('updates dropdown with new group transfer locations', async () => {
      await arrange();

      await waitForPromises();

      expect(findGroupTransferLocations()).toEqual(
        [...transferLocationsResponsePage1, ...transferLocationsResponsePage2].map(
          ({ full_name: fullName }) => fullName,
        ),
      );
    });
  });
});

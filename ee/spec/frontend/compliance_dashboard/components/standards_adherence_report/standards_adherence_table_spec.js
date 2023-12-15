import { GlAlert, GlLoadingIcon, GlTable, GlLink } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { mount, shallowMount } from '@vue/test-utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ComplianceStandardsAdherenceTable from 'ee/compliance_dashboard/components/standards_adherence_report/standards_adherence_table.vue';
import FixSuggestionsSidebar from 'ee/compliance_dashboard/components/standards_adherence_report/fix_suggestions_sidebar.vue';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import getProjectComplianceStandardsAdherence from 'ee/compliance_dashboard/graphql/compliance_standards_adherence.query.graphql';
import Pagination from 'ee/compliance_dashboard/components/shared/pagination.vue';
import { ROUTE_STANDARDS_ADHERENCE } from 'ee/compliance_dashboard/constants';
import Filters from 'ee/compliance_dashboard/components/standards_adherence_report/filters.vue';
import getProjectsInComplianceStandardsAdherence from 'ee/compliance_dashboard/graphql/compliance_projects_in_standards_adherence.query.graphql';
import { mapStandardsAdherenceQueryToFilters } from 'ee/compliance_dashboard/utils';
import { createComplianceAdherencesResponse } from '../../mock_data';

Vue.use(VueApollo);

describe('ComplianceStandardsAdherenceTable component', () => {
  let wrapper;
  let $router;
  let apolloProvider;
  const groupPath = 'example-group-path';

  const defaultAdherencesResponse = createComplianceAdherencesResponse({ count: 2 });
  const sentryError = new Error('GraphQL networkError');
  const mockGraphQlSuccess = jest.fn().mockResolvedValue(defaultAdherencesResponse);
  const mockGraphQlLoading = jest.fn().mockResolvedValue(new Promise(() => {}));
  const mockGraphQlError = jest.fn().mockRejectedValue(sentryError);
  const createMockApolloProvider = (resolverMock) => {
    return createMockApollo([
      [getProjectComplianceStandardsAdherence, resolverMock],
      [getProjectsInComplianceStandardsAdherence, mockGraphQlLoading],
    ]);
  };

  const findErrorMessage = () => wrapper.findComponent(GlAlert);
  const findStandardsAdherenceTable = () => wrapper.findComponent(GlTable);
  const findFixSuggestionSidebar = () => wrapper.findComponent(FixSuggestionsSidebar);
  const findTableLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTableHeaders = () => findStandardsAdherenceTable().findAll('th');
  const findTableRows = () => findStandardsAdherenceTable().findAll('tr');
  const findNthTableRow = (n) => findTableRows().at(n);
  const findFirstTableRowData = () => findNthTableRow(1).findAll('td');
  const findViewDetails = () => wrapper.findComponent(GlLink);
  const findPagination = () => wrapper.findComponent(Pagination);
  const findFilters = () => wrapper.findComponent(Filters);

  const openSidebar = async () => {
    await findViewDetails().trigger('click');
    await nextTick();
  };

  function createComponent(
    mountFn = shallowMount,
    props = {},
    resolverMock = mockGraphQlLoading,
    queryParams = {},
  ) {
    const currentQueryParams = { ...queryParams };
    $router = {
      push: jest.fn().mockImplementation(({ query }) => {
        Object.assign(currentQueryParams, query);
      }),
    };

    apolloProvider = createMockApolloProvider(resolverMock);

    wrapper = extendedWrapper(
      mountFn(ComplianceStandardsAdherenceTable, {
        apolloProvider,
        data() {
          return {
            projects: {
              list: [{ id: 'gid://gitlab/Project/1' }],
            },
          };
        },
        propsData: {
          groupPath,
          ...props,
        },
        mocks: {
          $router,
          $route: {
            name: ROUTE_STANDARDS_ADHERENCE,
            query: currentQueryParams,
          },
        },
      }),
    );
  }

  describe('default behavior', () => {
    beforeEach(() => {
      createComponent(mount);
    });

    it('does not render an error message', () => {
      expect(findErrorMessage().exists()).toBe(false);
    });

    it('has the correct table headers', () => {
      const headerTexts = findTableHeaders().wrappers.map((h) => h.text());

      expect(headerTexts).toStrictEqual([
        'Status',
        'Project',
        'Check',
        'Standard',
        'Last Scanned',
        'More Information',
      ]);
    });
  });

  describe('when the adherence query fails', () => {
    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException');
      createComponent(shallowMount, {}, mockGraphQlError);
    });

    it('renders the error message', async () => {
      await waitForPromises();

      expect(findErrorMessage().text()).toBe(
        'Unable to load the standards adherence report. Refresh the page and try again.',
      );
      expect(Sentry.captureException.mock.calls[0][0].networkError).toBe(sentryError);
    });
  });

  describe('when there are standards adherence checks available', () => {
    beforeEach(() => {
      createComponent(mount, {}, mockGraphQlSuccess);

      return waitForPromises();
    });

    it('does not render the table loading icon', () => {
      expect(mockGraphQlSuccess).toHaveBeenCalledTimes(1);

      expect(findTableLoadingIcon().exists()).toBe(false);
    });

    it('renders the table row properly for failed checks', () => {
      const infoCell = findNthTableRow(2).findAll('td').at(-1);
      expect(infoCell.text()).toMatchInterpolatedText('View details (fix available)');
    });

    describe('when check is `PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR`', () => {
      it('renders the table row properly', () => {
        const rowText = findFirstTableRowData().wrappers.map((e) => e.text());

        expect(rowText).toStrictEqual([
          'Success',
          'Example Project',
          'Prevent authors as approvers',
          'GitLab',
          'Jul 1, 2023',
          'View details',
        ]);
      });
    });

    describe('when check is `PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS`', () => {
      beforeEach(() => {
        const preventApprovalbyMRCommitersAdherencesResponse = createComplianceAdherencesResponse({
          checkName: 'PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS',
        });
        const mockResolver = jest
          .fn()
          .mockResolvedValue(preventApprovalbyMRCommitersAdherencesResponse);

        createComponent(mount, {}, mockResolver);

        return waitForPromises();
      });

      it('renders the table row properly', () => {
        const rowText = findFirstTableRowData().wrappers.map((e) => e.text());

        expect(rowText).toStrictEqual([
          'Success',
          'Example Project',
          'Prevent committers as approvers',
          'GitLab',
          'Jul 1, 2023',
          'View details',
        ]);
      });
    });

    describe('when check is `AT_LEAST_TWO_APPROVALS`', () => {
      beforeEach(() => {
        const atLeastTwoApprovalsAdherencesResponse = createComplianceAdherencesResponse({
          checkName: 'AT_LEAST_TWO_APPROVALS',
        });
        const mockResolver = jest.fn().mockResolvedValue(atLeastTwoApprovalsAdherencesResponse);

        createComponent(mount, {}, mockResolver);

        return waitForPromises();
      });

      it('renders the table row properly', () => {
        const rowText = findFirstTableRowData().wrappers.map((e) => e.text());

        expect(rowText).toStrictEqual([
          'Success',
          'Example Project',
          'At least two approvals',
          'GitLab',
          'Jul 1, 2023',
          'View details',
        ]);
      });
    });

    describe('pagination', () => {
      describe('when there is more than one page of standards adherence checks available', () => {
        it('shows the pagination button', () => {
          expect(findPagination().exists()).toBe(true);
        });

        describe('when a different size is selected', () => {
          it('resets to the first page and updates the page size', async () => {
            findPagination().vm.$emit('page-size-change', 50);
            await waitForPromises();

            expect($router.push).toHaveBeenCalledWith(
              expect.objectContaining({
                query: {
                  perPage: 50,
                },
              }),
            );
          });
        });

        describe('when the next page has been selected', () => {
          it('updates and calls the graphql query', async () => {
            findPagination().vm.$emit('next', 'next-value');
            await waitForPromises();

            expect($router.push).toHaveBeenCalledWith(
              expect.objectContaining({
                query: {
                  after: 'next-value',
                  before: undefined,
                },
              }),
            );
          });
        });

        describe('when the prev page has been selected', () => {
          it('updates and calls the graphql query', async () => {
            findPagination().vm.$emit('prev', 'prev-value');
            await waitForPromises();

            expect($router.push).toHaveBeenCalledWith(
              expect.objectContaining({
                query: {
                  after: undefined,
                  before: 'prev-value',
                },
              }),
            );
          });
        });
      });

      describe('when there is only one page of standards adherence checks available', () => {
        beforeEach(() => {
          const response = createComplianceAdherencesResponse({
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
            },
          });
          const mockResolver = jest.fn().mockResolvedValue(response);

          createComponent(mount, {}, mockResolver);
          return waitForPromises();
        });

        it('does not show the pagination', () => {
          expect(findPagination().exists()).toBe(false);
        });
      });
    });

    describe('filtering', () => {
      describe('by standard', () => {
        it('fetches the filtered adherences', async () => {
          findFilters().vm.$emit('submit', [{ type: 'standard', value: { data: 'GITLAB' } }]);
          await waitForPromises();

          expect(mockGraphQlSuccess).toHaveBeenCalledTimes(2);
          expect(mockGraphQlSuccess).toHaveBeenNthCalledWith(2, {
            after: undefined,
            fullPath: groupPath,
            filters: mapStandardsAdherenceQueryToFilters([
              { type: 'standard', value: { data: 'GITLAB' } },
            ]),
            first: 20,
          });
        });
      });

      describe('by project', () => {
        it('fetches the filtered adherences', async () => {
          findFilters().vm.$emit('submit', [
            { type: 'project', value: { data: 'gid://gitlab/Project/1' } },
          ]);
          await waitForPromises();

          expect(mockGraphQlSuccess).toHaveBeenCalledTimes(2);
          expect(mockGraphQlSuccess).toHaveBeenNthCalledWith(2, {
            after: undefined,
            fullPath: groupPath,
            filters: mapStandardsAdherenceQueryToFilters([
              { type: 'project', value: { data: 'gid://gitlab/Project/1' } },
            ]),
            first: 20,
          });
        });
      });

      describe('by check name', () => {
        it('fetches the filtered adherences', async () => {
          findFilters().vm.$emit('submit', [
            { type: 'check', value: { data: 'AT_LEAST_TWO_APPROVALS' } },
          ]);
          await waitForPromises();

          expect(mockGraphQlSuccess).toHaveBeenCalledTimes(2);
          expect(mockGraphQlSuccess).toHaveBeenNthCalledWith(2, {
            after: undefined,
            fullPath: groupPath,
            filters: mapStandardsAdherenceQueryToFilters([
              { type: 'check', value: { data: 'AT_LEAST_TWO_APPROVALS' } },
            ]),
            first: 20,
          });
        });
      });
    });
  });

  describe('when there are no standards adherence checks available', () => {
    beforeEach(() => {
      const noAdherencesResponse = createComplianceAdherencesResponse({ count: 0 });
      const mockResolver = jest.fn().mockResolvedValue(noAdherencesResponse);

      createComponent(mount, {}, mockResolver);

      return waitForPromises();
    });

    it('renders the empty table message', () => {
      expect(findStandardsAdherenceTable().text()).toContain(
        ComplianceStandardsAdherenceTable.noStandardsAdherencesFound,
      );
    });
  });

  describe('fixSuggestionSidebar', () => {
    beforeEach(() => {
      createComponent(mount, {}, mockGraphQlSuccess);

      return waitForPromises();
    });

    describe('closing the sidebar', () => {
      it('has the correct props when closed', async () => {
        await openSidebar();

        await findFixSuggestionSidebar().vm.$emit('close');

        expect(findFixSuggestionSidebar().props('groupPath')).toBe('example-group-path');
        expect(findFixSuggestionSidebar().props('showDrawer')).toBe(false);
        expect(findFixSuggestionSidebar().props('adherence')).toStrictEqual({});
      });
    });

    describe('opening the sidebar', () => {
      it('has the correct props when opened', async () => {
        await openSidebar();

        expect(findFixSuggestionSidebar().props('groupPath')).toBe('example-group-path');
        expect(findFixSuggestionSidebar().props('showDrawer')).toBe(true);
        expect(findFixSuggestionSidebar().props('adherence')).toStrictEqual(
          wrapper.vm.adherences.list[0],
        );
      });
    });
  });
});

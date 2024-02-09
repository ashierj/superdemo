import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import AdherenceBaseTable from 'ee/compliance_dashboard/components/standards_adherence_report/base_table.vue';
import GroupChecks from 'ee/compliance_dashboard/components/standards_adherence_report/group_checks.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import getProjectComplianceStandardsAdherence from 'ee/compliance_dashboard/graphql/compliance_standards_adherence.query.graphql';
import getProjectsInComplianceStandardsAdherence from 'ee/compliance_dashboard/graphql/compliance_projects_in_standards_adherence.query.graphql';
import { ROUTE_STANDARDS_ADHERENCE } from 'ee/compliance_dashboard/constants';

Vue.use(VueApollo);

describe('GroupChecks component', () => {
  let wrapper;
  let $router;
  let apolloProvider;
  const groupPath = 'example-group-path';

  const mockGraphQlLoading = jest.fn().mockResolvedValue(new Promise(() => {}));
  const createMockApolloProvider = (resolverMock) => {
    return createMockApollo([
      [getProjectComplianceStandardsAdherence, resolverMock],
      [getProjectsInComplianceStandardsAdherence, mockGraphQlLoading],
    ]);
  };

  const findChecks = () => wrapper.findComponent('[data-testid="adherences-grouped-by-checks"]');
  const findCheckGroupHeaders = () => findChecks().findAll('[data-testid="grouped-check"');

  function createComponent(
    mountFn = mount,
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
      mountFn(GroupChecks, {
        apolloProvider,
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
      createComponent();
    });

    it('lists all available checks', () => {
      expect(findCheckGroupHeaders().length).toBe(3);
      expect(findCheckGroupHeaders().at(0).text()).toMatch('Prevent authors as approvers');
      expect(findCheckGroupHeaders().at(1).text()).toMatch('Prevent committers as approvers');
      expect(findCheckGroupHeaders().at(2).text()).toMatch('At least two approvals');
    });

    it('contains correct `check` prop to AdherenceBaseTable component', () => {
      expect(findCheckGroupHeaders().at(0).findComponent(AdherenceBaseTable).props()).toMatchObject(
        {
          groupPath: 'example-group-path',
          filters: {},
          check: 'PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR',
        },
      );

      expect(findCheckGroupHeaders().at(1).findComponent(AdherenceBaseTable).props()).toMatchObject(
        {
          groupPath: 'example-group-path',
          filters: {},
          check: 'PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS',
        },
      );

      expect(findCheckGroupHeaders().at(2).findComponent(AdherenceBaseTable).props()).toMatchObject(
        {
          groupPath: 'example-group-path',
          filters: {},
          check: 'AT_LEAST_TWO_APPROVALS',
        },
      );
    });
  });
});

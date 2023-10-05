import { GlLoadingIcon, GlTable } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { mountExtended } from 'helpers/vue_test_utils_helper';

import { createComplianceFrameworksReportResponse } from 'ee_jest/compliance_dashboard/mock_data';
import FrameworksTable from 'ee/compliance_dashboard/components/frameworks_report/frameworks_table.vue';

Vue.use(VueApollo);

describe('FrameworksTable component', () => {
  let wrapper;

  const groupPath = 'group-path';

  const findTable = () => wrapper.findComponent(GlTable);
  const findTableHeaders = () => findTable().findAll('th div');
  const findTableRowData = (idx) => findTable().findAll('tbody > tr').at(idx).findAll('td');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findByTestId('frameworks-table-empty-state');

  const createComponent = (props = {}) => {
    return mountExtended(FrameworksTable, {
      propsData: {
        groupPath,
        ...props,
      },
      attachTo: document.body,
    });
  };

  describe('default behavior', () => {
    it('renders the loading indicator while loading', () => {
      wrapper = createComponent({ frameworks: [], isLoading: true });

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findTable().text()).not.toContain('No frameworks found');
    });

    it('renders the empty state when no frameworks found', () => {
      wrapper = createComponent({ frameworks: [], isLoading: false });

      const emptyState = findEmptyState();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(emptyState.exists()).toBe(true);
      expect(emptyState.text()).toBe('No frameworks found');
    });

    it('has the correct table headers', () => {
      wrapper = createComponent({ frameworks: [], isLoading: false });
      const headerTexts = findTableHeaders().wrappers.map((h) => h.text());

      expect(headerTexts).toStrictEqual(['Frameworks']);
    });
  });

  describe('when there are projects', () => {
    const frameworksResponse = createComplianceFrameworksReportResponse({ count: 2 });
    const frameworks = frameworksResponse.data.namespace.complianceFrameworks.nodes;
    beforeEach(() => {
      wrapper = createComponent({
        frameworks,
        isLoading: false,
      });
    });

    it.each(Object.keys(frameworks))('has the correct data for row %s', (idx) => {
      const [frameworkName] = findTableRowData(idx).wrappers.map((d) => d.text());
      expect(frameworkName).toBe(frameworks[idx].name);
    });
  });
});

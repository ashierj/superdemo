import { GlLoadingIcon, GlTable, GlLink, GlModal } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';

import {
  createComplianceFrameworksReportResponse,
  createComplianceFrameworksReportProjectsResponse,
} from 'ee_jest/compliance_dashboard/mock_data';
import FrameworksTable from 'ee/compliance_dashboard/components/frameworks_report/frameworks_table.vue';
import FrameworkBadge from 'ee/compliance_dashboard/components/shared/framework_badge.vue';
import FrameworkInfoDrawer from 'ee/compliance_dashboard/components/frameworks_report/framework_info_drawer.vue';
import { ROUTE_NEW_FRAMEWORK, ROUTE_EDIT_FRAMEWORK } from 'ee/compliance_dashboard/constants';

Vue.use(VueApollo);

describe('FrameworksTable component', () => {
  let wrapper;

  const frameworksResponse = createComplianceFrameworksReportResponse({ count: 2 });
  const projectsResponse = createComplianceFrameworksReportProjectsResponse({ count: 2 });
  const frameworks = frameworksResponse.data.namespace.complianceFrameworks.nodes;
  const projects = projectsResponse.data.group.projects.nodes;
  const rowCheckIndex = 0;
  const GlModalStub = stubComponent(GlModal, { methods: { show: jest.fn(), hide: jest.fn() } });

  const findTable = () => wrapper.findComponent(GlTable);
  const findTableHeaders = () => findTable().findAll('th div');
  const findTableRow = (idx) => findTable().findAll('tbody > tr').at(idx);
  const findTableRowData = (idx) => findTableRow(idx).findAll('td');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findByText('No frameworks found');
  const findTableLinks = () => wrapper.findAllComponents(GlLink);
  const findFrameworkInfoSidebar = () => wrapper.findComponent(FrameworkInfoDrawer);
  const findNewFrameworkButton = () => wrapper.findByText('New framework');
  const openSidebar = async () => {
    findTableRow(rowCheckIndex).trigger('click');
    await nextTick();
  };

  let routerPushMock;
  const createComponent = (props = {}) => {
    routerPushMock = jest.fn();
    return mountExtended(FrameworksTable, {
      propsData: {
        frameworks: [],
        projects: [],
        isLoading: true,
        ...props,
      },
      mocks: {
        $router: { push: routerPushMock },
      },
      stubs: {
        EditForm: true,
        GlModal: GlModalStub,
      },
      attachTo: document.body,
    });
  };

  describe('default behavior', () => {
    it('renders the loading indicator while loading', () => {
      wrapper = createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findTable().text()).not.toContain('No frameworks found');
    });

    it('renders the empty state when no frameworks found', () => {
      wrapper = createComponent({ isLoading: false });

      const emptyState = findEmptyState();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(emptyState.exists()).toBe(true);
      expect(emptyState.text()).toBe('No frameworks found');
    });

    it('has the correct table headers', () => {
      wrapper = createComponent({ isLoading: false });
      const headerTexts = findTableHeaders().wrappers.map((h) => h.text());

      expect(headerTexts).toStrictEqual(['Frameworks', 'Associated projects']);
    });

    it('navigates to add framework page when requested', () => {
      wrapper = createComponent({ isLoading: false });
      const newFrameworkButton = findNewFrameworkButton();

      newFrameworkButton.trigger('click');
      expect(routerPushMock).toHaveBeenCalledWith({ name: ROUTE_NEW_FRAMEWORK });
    });
  });

  describe('when there are projects', () => {
    beforeEach(() => {
      wrapper = createComponent({
        frameworks,
        projects,
        isLoading: false,
      });
    });

    it.each(Object.keys(frameworks))('has the correct data for row %s', (idx) => {
      const [frameworkName, associatedProjects] = findTableRowData(idx).wrappers.map((d) =>
        d.text(),
      );
      expect(frameworkName).toContain(frameworks[idx].name);
      expect(associatedProjects).toContain(projects[idx].name);
      expect(findTableLinks().wrappers).toHaveLength(2);
      expect(findTableLinks().wrappers.map((w) => w.attributes('href'))).toStrictEqual(
        projects.map((p) => p.webUrl),
      );
    });

    describe('when edit framework requested from framework badge', () => {
      beforeEach(() => {
        findTableRow(rowCheckIndex).findComponent(FrameworkBadge).vm.$emit('edit');
      });

      it('opens edit route with correct props', () => {
        expect(routerPushMock).toHaveBeenCalledWith({
          name: ROUTE_EDIT_FRAMEWORK,
          params: {
            id: frameworks[rowCheckIndex].id,
          },
        });
      });
    });

    describe('Sidebar', () => {
      describe('closing the sidebar', () => {
        it('has the correct props when closed', async () => {
          await openSidebar();

          await findFrameworkInfoSidebar().vm.$emit('close');

          expect(findFrameworkInfoSidebar().props('framework')).toBe(null);
        });
      });

      describe('opening the sidebar', () => {
        it('has the correct props when opened', async () => {
          await openSidebar();

          expect(findFrameworkInfoSidebar().props('framework')).toMatchObject(
            frameworks[rowCheckIndex],
          );
        });
      });
    });
  });
});

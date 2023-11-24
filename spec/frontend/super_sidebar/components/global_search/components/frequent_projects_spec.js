import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import FrequentItems from '~/super_sidebar/components/global_search/components/frequent_items.vue';
import FrequentProjects from '~/super_sidebar/components/global_search/components/frequent_projects.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import currentUserFrecentProjectsQuery from '~/super_sidebar/graphql/queries/current_user_frecent_projects.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { frecentProjectsMock } from '../../../mock_data';

Vue.use(VueApollo);

describe('FrequentlyVisitedProjects', () => {
  let wrapper;

  const projectsPath = '/mock/project/path';
  const currentUserFrecentProjectsQueryHandler = jest.fn().mockResolvedValue({
    data: {
      frecentProjects: frecentProjectsMock,
    },
  });

  const createComponent = (options) => {
    const mockApollo = createMockApollo([
      [currentUserFrecentProjectsQuery, currentUserFrecentProjectsQueryHandler],
    ]);

    wrapper = shallowMount(FrequentProjects, {
      apolloProvider: mockApollo,
      provide: {
        projectsPath,
      },
      ...options,
    });
  };

  const findFrequentItems = () => wrapper.findComponent(FrequentItems);
  const receivedAttrs = (wrapperInstance) => ({
    // See https://github.com/vuejs/test-utils/issues/2151.
    ...wrapperInstance.vm.$attrs,
  });

  it('passes project-specific props', () => {
    createComponent();

    expect(findFrequentItems().props()).toMatchObject({
      emptyStateText: 'Projects you visit often will appear here.',
      groupName: 'Frequently visited projects',
      viewAllItemsIcon: 'project',
      viewAllItemsText: 'View all my projects',
      viewAllItemsPath: projectsPath,
    });
  });

  it('loads frecent projects', () => {
    createComponent();

    expect(currentUserFrecentProjectsQueryHandler).toHaveBeenCalled();
    expect(findFrequentItems().props('loading')).toBe(true);
  });

  it('passes fetched projects to FrequentItems', async () => {
    createComponent();
    await waitForPromises();

    expect(findFrequentItems().props('items')).toEqual(frecentProjectsMock);
    expect(findFrequentItems().props('loading')).toBe(false);
  });

  it('passes attrs to FrequentItems', () => {
    createComponent({ attrs: { bordered: true, class: 'test-class' } });

    expect(findFrequentItems().classes()).toContain('test-class');
    expect(receivedAttrs(findFrequentItems())).toMatchObject({
      bordered: true,
    });
  });

  it('forwards listeners to FrequentItems', () => {
    const spy = jest.fn();
    createComponent({ listeners: { 'nothing-to-render': spy } });

    findFrequentItems().vm.$emit('nothing-to-render');

    expect(spy).toHaveBeenCalledTimes(1);
  });
});

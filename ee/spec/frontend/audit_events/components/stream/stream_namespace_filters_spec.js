import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox } from '@gitlab/ui';

import { shallowMount } from '@vue/test-utils';
import StreamNamespaceFilters from 'ee/audit_events/components/stream/stream_namespace_filters.vue';
import getNamespaceFiltersQuery from 'ee/audit_events/graphql/queries/get_namespace_filters.query.graphql';

import { AUDIT_STREAMS_FILTERING } from 'ee/audit_events/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import {
  mockAuditEventDefinitions,
  mockNamespaceFilter,
  getMockNamespaceFilters,
} from '../../mock_data';

Vue.use(VueApollo);

const namespaceFilters = getMockNamespaceFilters();
const getNamespaceFiltersQueryFn = jest.fn().mockResolvedValue(namespaceFilters);
const fakeApollo = createMockApollo([[getNamespaceFiltersQuery, getNamespaceFiltersQueryFn]]);

describe('StreamWithNamespaceFilters', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMount(StreamNamespaceFilters, {
      propsData: {
        value: mockNamespaceFilter(namespaceFilters.data.group.projects.nodes[0].fullPath),
        ...props,
      },
      apolloProvider: fakeApollo,
      provide: {
        auditEventDefinitions: mockAuditEventDefinitions,
        groupPath: 'group1',
      },
    });

    return nextTick();
  };

  const findCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  beforeEach(() => createComponent());

  it('renders correctly', () => {
    expect(findCollapsibleListbox().props()).toMatchObject({
      items: expect.any(Array),
      selected: namespaceFilters.data.group.projects.nodes[0].id,
      showSelectAllButtonLabel: AUDIT_STREAMS_FILTERING.SELECT_ALL,
      resetButtonLabel: AUDIT_STREAMS_FILTERING.UNSELECT_ALL,
      headerText: AUDIT_STREAMS_FILTERING.SELECT_NAMESPACE,
      noResultsText: StreamNamespaceFilters.i18n.NO_RESULT_TEXT,
      searchPlaceholder: StreamNamespaceFilters.i18n.SEARCH_PLACEHOLDER,
      multiple: false,
      searchable: true,
      toggleClass: 'gl-max-w-full',
    });
    expect(findCollapsibleListbox().classes('gl-max-w-full')).toBe(true);
  });

  describe('toggleText', () => {
    it('displays a placeholder when no events are selected', () => {
      createComponent({ value: mockNamespaceFilter('') });

      expect(findCollapsibleListbox().props('toggleText')).toBe(
        AUDIT_STREAMS_FILTERING.SELECT_NAMESPACE,
      );
    });

    it('displays a humanized event name when 1 event is selected', () => {
      createComponent({ value: mockNamespaceFilter('gitlab-org/project-1') });

      expect(findCollapsibleListbox().props('toggleText')).toBe('project 1');
    });
  });

  describe('events', () => {
    it('emits `input` event when selecting event', () => {
      const target = namespaceFilters.data.group.projects.nodes[1];

      findCollapsibleListbox().vm.$emit('select', target.id);

      expect(wrapper.emitted('input')).toStrictEqual([
        [
          {
            namespace: target.fullPath,
            type: 'project',
          },
        ],
      ]);
    });

    it('emits `input` with empty array when unselecting all', () => {
      findCollapsibleListbox().vm.$emit('reset');

      expect(wrapper.emitted('input')).toEqual([
        [
          {
            namespace: '',
            type: 'project',
          },
        ],
      ]);
    });
  });

  describe('search', () => {
    it('filters items correctly when searching', async () => {
      await findCollapsibleListbox().vm.$emit('search', 'project');
      await nextTick();

      expect(getNamespaceFiltersQueryFn).toHaveBeenCalledWith({
        fullPath: 'group1',
        search: 'project',
      });
    });
  });
});

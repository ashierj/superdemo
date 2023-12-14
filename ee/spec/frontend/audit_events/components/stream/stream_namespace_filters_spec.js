import { GlCollapsibleListbox } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { shallowMount } from '@vue/test-utils';
import StreamNamespaceFilters from 'ee/audit_events/components/stream/stream_namespace_filters.vue';
import { AUDIT_STREAMS_FILTERING } from 'ee/audit_events/constants';
import {
  mockExternalDestinations,
  mockAuditEventDefinitions,
  createAllGroups,
  createAllProjects,
  mockNamespaceFilter,
} from '../../mock_data';

const EXPECTED_ITEMS = [
  {
    text: 'Groups',
    options: [
      { text: 'sub group 0', value: 'gitlab-org/sub-group-0', type: 'Groups' },
      { text: 'sub group 1', value: 'gitlab-org/sub-group-1', type: 'Groups' },
    ],
  },
  {
    text: 'Projects',
    options: [
      { text: 'project 0', value: 'gitlab-org/project-0', type: 'Projects' },
      { text: 'project 1', value: 'gitlab-org/project-1', type: 'Projects' },
      { text: 'project 2', value: 'gitlab-org/project-2', type: 'Projects' },
    ],
  },
];

describe('StreamWithNamespaceFilters', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMount(StreamNamespaceFilters, {
      propsData: {
        value: mockNamespaceFilter(mockExternalDestinations[1].namespaceFilter.namespace.fullPath),
        ...props,
      },
      provide: {
        auditEventDefinitions: mockAuditEventDefinitions,
        allGroups: createAllGroups(2),
        allProjects: createAllProjects(3),
      },
    });
  };

  const findCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  beforeEach(() => {
    createComponent();
  });

  it('renders correctly', () => {
    expect(findCollapsibleListbox().props()).toMatchObject({
      items: EXPECTED_ITEMS,
      selected: mockExternalDestinations[1].namespaceFilter.namespace.fullPath,
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
      findCollapsibleListbox().vm.$emit(
        'select',
        mockExternalDestinations[1].namespaceFilter.namespace.fullPath,
      );

      expect(wrapper.emitted('input')).toStrictEqual([
        [
          {
            namespace: mockExternalDestinations[1].namespaceFilter.namespace.fullPath,
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
    beforeEach(() => {
      jest.spyOn(fuzzaldrinPlus, 'filter');
    });

    it('does not filter items if searchTerm is empty string', async () => {
      await findCollapsibleListbox().vm.$emit('search', '');

      expect(fuzzaldrinPlus.filter).not.toHaveBeenCalled();
      expect(findCollapsibleListbox().props('items')).toMatchObject(EXPECTED_ITEMS);
    });

    it('filters items correctly when searching', async () => {
      // Omit 'e' in 'user' to test for fuzzy search
      await findCollapsibleListbox().vm.$emit('search', 'project');

      expect(findCollapsibleListbox().props('items')).toMatchObject([EXPECTED_ITEMS[1]]);
      expect(fuzzaldrinPlus.filter).toHaveBeenCalled();
    });
  });
});

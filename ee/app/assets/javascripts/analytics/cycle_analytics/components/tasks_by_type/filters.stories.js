import { withVuexStore } from 'storybook_addons/vuex_store';
import { defaultGroupLabels, subjectFilter } from '../stories_constants';
import { TASKS_BY_TYPE_MAX_LABELS } from '../../constants';
import TasksByTypeFilters from './filters.vue';

export default {
  component: TasksByTypeFilters,
  title: 'ee/analytics/cycle_analytics/components/tasks_by_type/filters',
  decorators: [withVuexStore],
};

const Template = (args, { argTypes, createVuexStore }) => ({
  components: { TasksByTypeFilters },
  props: Object.keys(argTypes),
  template: '<tasks-by-type-filters v-bind="$props" />',
  store: createVuexStore({
    state: {
      defaultGroupLabels,
    },
    getters: {
      namespacePath: () => 'fake/namespace/path',
    },
  }),
});

export const Default = Template.bind({});
Default.args = {
  maxLabels: TASKS_BY_TYPE_MAX_LABELS,
  selectedLabelNames: [],
  subjectFilter,
  defaultGroupLabels,
};

export const SelectedLabels = Template.bind({});
SelectedLabels.args = {
  maxLabels: TASKS_BY_TYPE_MAX_LABELS,
  selectedLabelNames: ['ready', 'done'],
  subjectFilter,
  defaultGroupLabels,
};

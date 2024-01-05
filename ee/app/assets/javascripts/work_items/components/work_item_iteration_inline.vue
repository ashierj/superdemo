<script>
import { GlCollapsibleListbox, GlFormGroup, GlSkeletonLoader } from '@gitlab/ui';
import { debounce } from 'lodash';
import { getIterationPeriod, groupOptionsByIterationCadences } from 'ee/iterations/utils';
import projectIterationsQuery from 'ee/work_items/graphql/project_iterations.query.graphql';
import { STATUS_OPEN } from '~/issues/constants';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import Tracking from '~/tracking';
import {
  I18N_WORK_ITEM_ERROR_UPDATING,
  I18N_WORK_ITEM_FETCH_ITERATIONS_ERROR,
  sprintfWorkItem,
  TRACKING_CATEGORY_SHOW,
} from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';

const noIterationId = 'no-iteration-id';
const noIterationItem = { text: s__('WorkItem|No iteration'), value: noIterationId };

export default {
  i18n: {
    ITERATION: s__('WorkItem|Iteration'),
    NONE: s__('WorkItem|None'),
    ITERATION_PLACEHOLDER: s__('WorkItem|Add to iteration'),
    NO_MATCHING_RESULTS: s__('WorkItem|No matching results'),
    NO_ITERATION: s__('WorkItem|No iteration'),
  },
  components: {
    GlCollapsibleListbox,
    GlFormGroup,
    GlSkeletonLoader,
  },
  mixins: [Tracking.mixin()],
  inject: ['hasIterationsFeature'],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    iteration: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
      shouldFetch: false,
      selectedIterationId: this.iteration?.id,
      updateInProgress: false,
      iterations: [],
    };
  },
  computed: {
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_iteration',
        property: `type_${this.workItemType}`,
      };
    },
    iterationPeriod() {
      return this.iteration?.period || getIterationPeriod(this.iteration);
    },
    iterationTitle() {
      return this.iteration?.title || this.iterationPeriod;
    },
    listboxItems() {
      return [
        {
          text: this.$options.i18n.NO_ITERATION,
          textSrOnly: true,
          options: [noIterationItem],
        },
      ].concat(groupOptionsByIterationCadences(this.iterations));
    },
    isLoadingIterations() {
      return this.$apollo.queries.iterations.loading;
    },
    dropdownClasses() {
      return {
        'gl-text-gray-500!': this.canUpdate && !this.iteration?.id,
      };
    },
    noIterationDefaultText() {
      return this.canUpdate ? this.$options.i18n.ITERATION_PLACEHOLDER : this.$options.i18n.NONE;
    },
    dropdownText() {
      return this.iteration?.id && this.iteration?.id !== noIterationId
        ? this.iterationTitle
        : this.noIterationDefaultText;
    },
  },
  apollo: {
    iterations: {
      query: projectIterationsQuery,
      variables() {
        const search = this.searchTerm ? `"${this.searchTerm}"` : '';
        return {
          fullPath: this.fullPath,
          title: search,
          state: STATUS_OPEN,
        };
      },
      update(data) {
        return data.workspace?.attributes?.nodes || [];
      },
      skip() {
        return !this.shouldFetch;
      },
      error() {
        this.$emit('error', I18N_WORK_ITEM_FETCH_ITERATIONS_ERROR);
      },
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    setSearchKey(value) {
      this.searchTerm = value;
    },
    onDropdownShown() {
      this.shouldFetch = true;
    },
    onDropdownHide() {
      this.searchTerm = '';
      this.shouldFetch = false;
    },
    async updateWorkItemIteration() {
      const selectedIteration =
        this.iterations.find(({ id }) => id === this.selectedIterationId) ?? noIterationItem;

      if (this.iteration?.id === selectedIteration?.id) {
        return;
      }

      this.updateInProgress = true;
      try {
        const {
          data: {
            workItemUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              iterationWidget: {
                iterationId:
                  this.selectedIterationId === noIterationId ? null : this.selectedIterationId,
              },
            },
          },
        });
        this.track('updated_iteration');
        if (errors.length > 0) {
          throw new Error(errors.join('\n'));
        }
      } catch (error) {
        const msg = sprintfWorkItem(I18N_WORK_ITEM_ERROR_UPDATING, this.workItemType);
        this.$emit('error', msg);
        Sentry.captureException(error);
      }
      this.updateInProgress = false;
    },
  },
};
</script>

<template>
  <gl-form-group
    v-if="hasIterationsFeature"
    class="work-item-dropdown gl-flex-nowrap"
    label-for="iteration-value"
    :label="$options.i18n.ITERATION"
    label-class="gl-pb-0! gl-overflow-wrap-break gl-mt-3 work-item-field-label"
    label-cols="3"
    label-cols-lg="2"
  >
    <span
      v-if="!canUpdate"
      class="gl-text-secondary gl-ml-4 gl-mt-3 gl-display-inline-block gl-line-height-normal work-item-field-value"
      data-testid="disabled-text"
    >
      {{ dropdownText }}
    </span>

    <gl-collapsible-listbox
      v-else
      id="iteration-value"
      v-model="selectedIterationId"
      category="tertiary"
      class="work-item-field-value"
      :items="listboxItems"
      :loading="updateInProgress"
      searchable
      :toggle-class="dropdownClasses"
      :toggle-text="dropdownText"
      @hidden="onDropdownHide"
      @search="debouncedSearchKeyUpdate"
      @select="updateWorkItemIteration"
      @shown="onDropdownShown"
    >
      <template #footer>
        <gl-skeleton-loader v-if="isLoadingIterations" :height="90">
          <rect width="380" height="10" x="10" y="15" rx="4" />
          <rect width="280" height="10" x="10" y="30" rx="4" />
          <rect width="380" height="10" x="10" y="50" rx="4" />
          <rect width="280" height="10" x="10" y="65" rx="4" />
        </gl-skeleton-loader>
        <div
          v-else-if="!iterations.length"
          aria-live="assertive"
          class="gl-pl-7 gl-pr-5 gl-py-3 gl-font-base gl-text-gray-600"
          data-testid="no-results-text"
        >
          {{ $options.i18n.NO_MATCHING_RESULTS }}
        </div>
      </template>
    </gl-collapsible-listbox>
  </gl-form-group>
</template>

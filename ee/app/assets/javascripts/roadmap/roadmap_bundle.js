import Vue from 'vue';
import VueApollo from 'vue-apollo';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';

import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { queryToObject } from '~/lib/utils/url_utility';
import Translate from '~/vue_shared/translate';

import RoadmapApp from './components/roadmap_app.vue';
import localRoadmapSettingsQuery from './queries/local_roadmap_settings.query.graphql';
import { defaultClient } from './graphql';
import {
  DATE_RANGES,
  PROGRESS_WEIGHT,
  UNSUPPORTED_ROADMAP_PARAMS,
  MILESTONES_ALL,
  ALLOWED_SORT_VALUES,
} from './constants';

import createStore from './store';
import {
  getPresetTypeForTimeframeRangeType,
  getTimeframeForRangeType,
} from './utils/roadmap_utils';

Vue.use(Translate);
Vue.use(VueApollo);

export default () => {
  const el = document.getElementById('js-roadmap');

  if (!el) {
    return false;
  }

  const { dataset } = el;

  const rawFilterParams = queryToObject(window.location.search, {
    gatherArrays: true,
  });

  const filterParams = {
    ...convertObjectPropsToCamelCase(rawFilterParams, {
      dropKeys: UNSUPPORTED_ROADMAP_PARAMS,
    }),
    // We shall put parsed value of `confidential` only
    // when it is defined.
    ...(rawFilterParams.confidential && {
      confidential: parseBoolean(rawFilterParams.confidential),
    }),

    ...(rawFilterParams.epicIid && {
      epicIid: rawFilterParams.epicIid,
    }),
  };

  defaultClient.cache.writeQuery({
    query: localRoadmapSettingsQuery,
    data: {
      localRoadmapSettings: {
        __typename: 'LocalRoadmapSettings',
        filterParams,
      },
    },
  });

  const apolloProvider = new VueApollo({
    defaultClient,
  });

  return new Vue({
    el,
    name: 'RoadmapRoot',
    apolloProvider,
    store: createStore(),
    components: {
      RoadmapApp,
    },
    provide() {
      return {
        newEpicPath: dataset.newEpicPath,
        listEpicsPath: dataset.listEpicsPath,
        epicsDocsPath: dataset.epicsDocsPath,
        groupFullPath: dataset.fullPath,
        groupLabelsPath: dataset.groupLabelsEndpoint,
        groupMilestonesPath: dataset.groupMilestonesEndpoint,
        canCreateEpic: parseBoolean(dataset.canCreateEpic),
        emptyStateIllustrationPath: dataset.emptyStateIllustration,
        fullPath: dataset.fullPath,
        epicIid: dataset.iid,
        allowSubEpics: parseBoolean(dataset.allowSubEpics),
        allowScopedLabels: dataset.allowScopedLabels,
        hasScopedLabelsFeature: dataset.allowScopedLabels,
        isChildEpics: parseBoolean(dataset.childEpics),
        currentGroupId: parseInt(dataset.groupId, 10),
      };
    },
    data() {
      const timeframeRangeType =
        Object.keys(DATE_RANGES).indexOf(dataset.timeframeRangeType) > -1
          ? dataset.timeframeRangeType
          : DATE_RANGES.CURRENT_QUARTER;
      const presetType = getPresetTypeForTimeframeRangeType(timeframeRangeType, dataset.presetType);
      const timeframe = getTimeframeForRangeType({
        timeframeRangeType,
        presetType,
      });

      return {
        epicsState: dataset.epicsState,
        sortedBy: ALLOWED_SORT_VALUES.includes(dataset.sortedBy)
          ? dataset.sortedBy
          : ALLOWED_SORT_VALUES[0],
        timeframeRangeType,
        presetType,
        timeframe,
        progressTracking: rawFilterParams.progress || PROGRESS_WEIGHT,
        isProgressTrackingActive:
          rawFilterParams.show_progress === undefined
            ? true
            : parseBoolean(rawFilterParams.show_progress),
        isShowingMilestones:
          rawFilterParams.show_milestones === undefined
            ? true
            : parseBoolean(rawFilterParams.show_milestones),
        milestonesType: rawFilterParams.milestones_type || MILESTONES_ALL,
        isShowingLabels: parseBoolean(rawFilterParams.show_labels),
      };
    },
    created() {
      this.setInitialData({
        sortedBy: this.sortedBy,
        timeframeRangeType: this.timeframeRangeType,
        presetType: this.presetType,
        epicsState: this.epicsState,
        timeframe: this.timeframe,
        isProgressTrackingActive: this.isProgressTrackingActive,
        progressTracking: this.progressTracking,
        isShowingMilestones: this.isShowingMilestones,
        milestonesType: this.milestonesType,
        isShowingLabels: this.isShowingLabels,
      });
    },
    methods: {
      ...mapActions(['setInitialData']),
    },
    render(createElement) {
      return createElement('roadmap-app');
    },
  });
};

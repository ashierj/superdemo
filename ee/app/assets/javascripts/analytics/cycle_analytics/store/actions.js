import dateFormat from 'dateformat';
import axios from '~/lib/utils/axios_utils';
import createFlash, { hideFlash } from '~/flash';
import { __ } from '~/locale';
import Api from '~/api';
import httpStatus from '~/lib/utils/http_status';
import * as types from './mutation_types';
import { dateFormats } from '../../shared/constants';

const removeError = () => {
  const flashEl = document.querySelector('.flash-alert');
  if (flashEl) {
    hideFlash(flashEl);
  }
};

export const setCycleAnalyticsDataEndpoint = ({ commit }, groupPath) =>
  commit(types.SET_CYCLE_ANALYTICS_DATA_ENDPOINT, groupPath);

export const setStageDataEndpoint = ({ commit }, stageSlug) =>
  commit(types.SET_STAGE_DATA_ENDPOINT, stageSlug);
export const setSelectedGroup = ({ commit }, group) => commit(types.SET_SELECTED_GROUP, group);
export const setSelectedProjects = ({ commit }, projectIds) =>
  commit(types.SET_SELECTED_PROJECTS, projectIds);
export const setSelectedStageName = ({ commit }, stageName) =>
  commit(types.SET_SELECTED_STAGE_NAME, stageName);

export const setDateRange = (
  { commit, dispatch, state },
  { skipFetch = false, startDate, endDate },
) => {
  commit(types.SET_DATE_RANGE, { startDate, endDate });

  if (skipFetch) return false;

  return dispatch('fetchCycleAnalyticsData', { state, dispatch });
};

export const requestStageData = ({ commit }) => commit(types.REQUEST_STAGE_DATA);
export const receiveStageDataSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_STAGE_DATA_SUCCESS, data);

export const receiveStageDataError = ({ commit }) => {
  commit(types.RECEIVE_STAGE_DATA_ERROR);
  createFlash(__('There was an error while fetching cycle analytics data.'));
};

export const fetchStageData = ({ state, dispatch }) => {
  dispatch('requestStageData');

  axios
    .get(state.endpoints.stageData, {
      params: {
        'cycle_analytics[created_after]': dateFormat(state.startDate, dateFormats.isoDate),
        'cycle_analytics[created_before]': dateFormat(state.endDate, dateFormats.isoDate),
        'cycle_analytics[project_ids]': state.selectedProjectIds,
      },
    })
    .then(({ data }) => dispatch('receiveStageDataSuccess', data))
    .catch(error => dispatch('receiveStageDataError', error));
};

export const requestCycleAnalyticsData = ({ commit }) => commit(types.REQUEST_CYCLE_ANALYTICS_DATA);
export const receiveCycleAnalyticsDataSuccess = ({ state, commit, dispatch }, data) => {
  commit(types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS, data);
  const { stages = [] } = state;
  if (stages && stages.length) {
    removeError();

    const { slug } = stages[0];
    dispatch('setStageDataEndpoint', slug);
    dispatch('fetchStageData');
  } else {
    createFlash(__('There was an error while fetching cycle analytics data.'));
  }
};

export const receiveCycleAnalyticsDataError = ({ commit }, { response }) => {
  const { status } = response;
  commit(types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR, status);

  if (status !== httpStatus.FORBIDDEN)
    createFlash(__('There was an error while fetching cycle analytics data.'));
};

export const fetchCycleAnalyticsData = ({ state, dispatch }) => {
  dispatch('requestCycleAnalyticsData');

  axios
    .get(state.endpoints.cycleAnalyticsData, {
      params: {
        'cycle_analytics[created_after]': dateFormat(state.startDate, dateFormats.isoDate),
        'cycle_analytics[created_before]': dateFormat(state.endDate, dateFormats.isoDate),
        'cycle_analytics[project_ids]': state.selectedProjectIds,
      },
    })
    .then(({ data }) => dispatch('receiveCycleAnalyticsDataSuccess', data))
    .catch(error => dispatch('receiveCycleAnalyticsDataError', error));
};

export const hideCustomStageForm = ({ commit }) => commit(types.HIDE_CUSTOM_STAGE_FORM);
export const showCustomStageForm = ({ commit }) => commit(types.SHOW_CUSTOM_STAGE_FORM);

export const receiveGroupLabelsSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_GROUP_LABELS_SUCCESS, data);

export const receiveGroupLabelsError = ({ commit }, error) => {
  commit(types.RECEIVE_GROUP_LABELS_ERROR, error);
  createFlash(__('There was an error fetching label data for the selected group'));
};

export const requestGroupLabels = ({ commit }) => commit(types.REQUEST_GROUP_LABELS);

export const fetchGroupLabels = ({ dispatch }, groupPath) => {
  dispatch('requestGroupLabels');

  return Api.groupLabels(groupPath)
    .then(data => dispatch('receiveGroupLabelsSuccess', data))
    .catch(error => dispatch('receiveGroupLabelsError', error));
};

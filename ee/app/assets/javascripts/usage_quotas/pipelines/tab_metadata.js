import { __ } from '~/locale';
import { parseBoolean } from '~/lib/utils/common_utils';
import apolloProvider from 'ee/usage_quotas/shared/provider';
import { PIPELINES_TAB_METADATA_EL_SELECTOR } from '../constants';
import PipelineUsageApp from './components/app.vue';

export const parseProvideData = (el) => {
  const {
    pageSize,
    namespacePath,
    namespaceId,
    namespaceActualPlanName,
    userNamespace,
    ciMinutesAnyProjectEnabled,
    ciMinutesDisplayMinutesAvailableData,
    ciMinutesLastResetDate,
    ciMinutesMonthlyMinutesLimit,
    ciMinutesMonthlyMinutesUsed,
    ciMinutesMonthlyMinutesUsedPercentage,
    ciMinutesPurchasedMinutesLimit,
    ciMinutesPurchasedMinutesUsed,
    ciMinutesPurchasedMinutesUsedPercentage,
    buyAdditionalMinutesPath,
    buyAdditionalMinutesTarget,
  } = el.dataset;

  return {
    pageSize: Number(pageSize),
    namespacePath,
    namespaceId,
    namespaceActualPlanName,
    userNamespace: parseBoolean(userNamespace),
    ciMinutesAnyProjectEnabled: parseBoolean(ciMinutesAnyProjectEnabled),
    ciMinutesDisplayMinutesAvailableData: parseBoolean(ciMinutesDisplayMinutesAvailableData),
    ciMinutesLastResetDate,
    // Limit and Usage could be a number or a string (e.g. `Unlimited`) so we shouldn't parse these
    ciMinutesMonthlyMinutesLimit,
    ciMinutesMonthlyMinutesUsed,
    ciMinutesMonthlyMinutesUsedPercentage,
    ciMinutesPurchasedMinutesLimit,
    ciMinutesPurchasedMinutesUsed,
    ciMinutesPurchasedMinutesUsedPercentage,
    buyAdditionalMinutesPath,
    buyAdditionalMinutesTarget,
  };
};

export const getPipelineTabMetadata = ({ includeEl = false } = {}) => {
  const el = document.querySelector(PIPELINES_TAB_METADATA_EL_SELECTOR);

  if (!el) return false;

  const pipelineTabMetadata = {
    title: __('Pipelines'),
    hash: '#pipelines-quota-tab',
    component: {
      name: 'PipelineUsageTab',
      provide: parseProvideData(el),
      apolloProvider,
      render(createElement) {
        return createElement(PipelineUsageApp);
      },
    },
  };

  if (includeEl) {
    pipelineTabMetadata.component.el = el;
  }

  return pipelineTabMetadata;
};

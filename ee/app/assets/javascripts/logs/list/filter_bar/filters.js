import {
  prepareTokens,
  processFilters,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

export const SERVICE_NAME_FILTER_TOKEN_TYPE = 'service-name';
export const SEVERITY_NAME_FILTER_TOKEN_TYPE = 'severity-name';
export const TRACE_ID_FILTER_TOKEN_TYPE = 'trace-id';
export const SPAN_ID_FILTER_TOKEN_TYPE = 'span-id';
export const FINGERPRINT_FILTER_TOKEN_TYPE = 'fingerprint';
export const TRACE_FLAGS_FILTER_TOKEN_TYPE = 'trace-flags';
export const ATTRIBUTE_FILTER_TOKEN_TYPE = 'attribute';
export const RESOURCE_ATTRIBUTE_FILTER_TOKEN_TYPE = 'resource-attribute';

export function filterObjToFilterToken(filters) {
  return prepareTokens({
    [SERVICE_NAME_FILTER_TOKEN_TYPE]: filters.service,
    [SEVERITY_NAME_FILTER_TOKEN_TYPE]: filters.severityName,
    [TRACE_ID_FILTER_TOKEN_TYPE]: filters.traceId,
    [SPAN_ID_FILTER_TOKEN_TYPE]: filters.spanId,
    [FINGERPRINT_FILTER_TOKEN_TYPE]: filters.fingerprint,
    [TRACE_FLAGS_FILTER_TOKEN_TYPE]: filters.traceFlags,
    [ATTRIBUTE_FILTER_TOKEN_TYPE]: filters.attribute,
    [RESOURCE_ATTRIBUTE_FILTER_TOKEN_TYPE]: filters.resourceAttribute,
    [FILTERED_SEARCH_TERM]: filters.search,
  });
}

export function filterTokensToFilterObj(tokens) {
  const {
    [FILTERED_SEARCH_TERM]: search,
    [SERVICE_NAME_FILTER_TOKEN_TYPE]: service,
    [SEVERITY_NAME_FILTER_TOKEN_TYPE]: severityName,
    [TRACE_ID_FILTER_TOKEN_TYPE]: traceId,
    [SPAN_ID_FILTER_TOKEN_TYPE]: spanId,
    [FINGERPRINT_FILTER_TOKEN_TYPE]: fingerprint,
    [TRACE_FLAGS_FILTER_TOKEN_TYPE]: traceFlags,
    [ATTRIBUTE_FILTER_TOKEN_TYPE]: attribute,
    [RESOURCE_ATTRIBUTE_FILTER_TOKEN_TYPE]: resourceAttribute,
  } = processFilters(tokens);

  return {
    search,
    service,
    severityName,
    traceId,
    spanId,
    fingerprint,
    traceFlags,
    attribute,
    resourceAttribute,
  };
}

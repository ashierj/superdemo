import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

import {
  REPORT_TYPE_LIST,
  REPORT_TYPE_URL,
  REPORT_TYPE_DIFF,
  REPORT_TYPE_NAMED_LIST,
  REPORT_TYPE_TEXT,
  REPORT_TYPE_VALUE,
  REPORT_TYPE_MODULE_LOCATION,
  REPORT_TYPE_FILE_LOCATION,
  REPORT_TYPE_TABLE,
  REPORT_TYPE_CODE,
  REPORT_TYPE_MARKDOWN,
  REPORT_TYPE_COMMIT,
} from './constants';

export const getComponentNameForType = (reportType) =>
  `ReportType${capitalizeFirstCharacter(reportType)}`;

export const REPORT_COMPONENTS = {
  [getComponentNameForType(REPORT_TYPE_LIST)]: () => import('./list.vue'),
  [getComponentNameForType(REPORT_TYPE_URL)]: () => import('./url.vue'),
  [getComponentNameForType(REPORT_TYPE_DIFF)]: () => import('./diff.vue'),
  [getComponentNameForType(REPORT_TYPE_NAMED_LIST)]: () => import('./named_list.vue'),
  [getComponentNameForType(REPORT_TYPE_TEXT)]: () => import('./value.vue'),
  [getComponentNameForType(REPORT_TYPE_VALUE)]: () => import('./value.vue'),
  [getComponentNameForType(REPORT_TYPE_MODULE_LOCATION)]: () => import('./module_location.vue'),
  [getComponentNameForType(REPORT_TYPE_FILE_LOCATION)]: () => import('./file_location.vue'),
  [getComponentNameForType(REPORT_TYPE_TABLE)]: () => import('./table.vue'),
  [getComponentNameForType(REPORT_TYPE_CODE)]: () => import('./code.vue'),
  [getComponentNameForType(REPORT_TYPE_MARKDOWN)]: () => import('./markdown.vue'),
  [getComponentNameForType(REPORT_TYPE_COMMIT)]: () => import('./commit.vue'),
};

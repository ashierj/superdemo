import { helpPagePath } from '~/helpers/help_page_helper';

export const GRIDSTACK_MARGIN_X = 16;
export const GRIDSTACK_MARGIN_Y = 8;
export const GRIDSTACK_CSS_HANDLE = '.grid-stack-item-handle';

/* Magic number 125px:
 * After allowing for padding, and the panel title row, this leaves us with minimum 48px height for the cell content.
 * This means text/content with our spacing scale can fit up to 49px without scrolling.
 */
export const GRIDSTACK_CELL_HEIGHT = '125px';
export const GRIDSTACK_MIN_ROW = 1;

export const PANEL_TROUBLESHOOTING_URL = helpPagePath(
  '/user/analytics/analytics_dashboards#troubleshooting',
);

export const PANEL_POPOVER_DELAY = {
  hide: 500,
};

export const CURSOR_GRABBING_CLASS = 'gl-cursor-grabbing!';

export const NEW_DASHBOARD_SLUG = 'new';

export const DASHBOARD_DOCUMENTATION_LINKS = {
  value_stream_dashboard: '/help/user/analytics/value_streams_dashboard',
};

export const CATEGORY_SINGLE_STATS = 'singleStats';
export const CATEGORY_TABLES = 'tables';
export const CATEGORY_CHARTS = 'charts';

<script>
import { GridStack } from 'gridstack';
import { breakpoints } from '@gitlab/ui/dist/utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { cloneWithoutReferences } from '~/lib/utils/common_utils';
import { loadCSSFile } from '~/lib/utils/css_utils';
import {
  GRIDSTACK_MARGIN,
  GRIDSTACK_CSS_HANDLE,
  GRIDSTACK_CELL_HEIGHT,
  GRIDSTACK_MIN_ROW,
  CURSOR_GRABBING_CLASS,
} from './constants';
import { getUniquePanelId } from './utils';

export default {
  name: 'GridstackWrapper',
  props: {
    value: {
      type: Object,
      required: true,
    },
    editing: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      dashboard: this.createDraftDashboard(this.value),
      grid: undefined,
      cssLoaded: false,
      mounted: false,
    };
  },
  computed: {
    mountedWithCss() {
      return this.cssLoaded && this.mounted;
    },
  },
  watch: {
    mountedWithCss(mountedWithCss) {
      if (mountedWithCss) {
        this.initGridStack();
      }
    },
    editing(value) {
      this.grid?.setStatic(!value);
    },
  },
  mounted() {
    this.mounted = true;
  },
  beforeDestroy() {
    this.mounted = false;
    this.grid?.destroy();
  },
  async created() {
    try {
      await loadCSSFile(gon.gridstack_css_path);
      this.cssLoaded = true;
    } catch (e) {
      Sentry.captureException(e);
    }
  },
  methods: {
    createDraftDashboard(dashboard) {
      const draft = cloneWithoutReferences(dashboard);
      return {
        ...draft,
        // Gridstack requires unique panel IDs for mutations
        panels: draft.panels.map((panel) => ({
          ...panel,
          id: getUniquePanelId(),
        })),
      };
    },
    initGridStack() {
      this.grid = GridStack.init({
        staticGrid: !this.editing,
        margin: GRIDSTACK_MARGIN,
        handle: GRIDSTACK_CSS_HANDLE,
        cellHeight: GRIDSTACK_CELL_HEIGHT,
        minRow: GRIDSTACK_MIN_ROW,
        columnOpts: { breakpoints: [{ w: breakpoints.md, c: 1 }] },
        alwaysShowResizeHandle: true,
        animate: false,
      });

      this.grid.on('dragstart', () => {
        this.$el.classList.add(CURSOR_GRABBING_CLASS);
      });
      this.grid.on('dragstop', () => {
        this.$el.classList.remove(CURSOR_GRABBING_CLASS);
      });
      this.grid.on('change', (_, items) => {
        items.forEach((item) => {
          this.updatePanelWithGridStackItem(item);
        });
      });
      this.grid.on('added', (_, items) => {
        items.forEach((item) => {
          this.updatePanelWithGridStackItem(item);
        });
      });
    },
    registerNewGridPanelElement(panelId) {
      this.grid.makeWidget(`#${panelId}`);

      document.getElementById(panelId)?.scrollIntoView({ behavior: 'smooth' });
    },
    getGridAttribute(panel, attribute) {
      const { gridAttributes = {} } = panel;

      return gridAttributes[attribute];
    },
    deletePanel(panel) {
      const panelIndex = this.dashboard.panels.indexOf(panel);
      this.dashboard.panels.splice(panelIndex, 1);

      this.grid.removeWidget(document.getElementById(panel.id), false);

      this.emitChange();
    },
    async addPanels(panels) {
      const panelIds = panels.map(({ id }) => id);

      this.dashboard.panels.push(...panels);

      // Wait for the panel elements to render
      await this.$nextTick();

      panelIds.forEach((id) => this.registerNewGridPanelElement(id));

      this.emitChange();
    },
    updatePanelWithGridStackItem(item) {
      const updatedPanel = this.dashboard.panels.find((panel) => panel.id === item.id);
      if (updatedPanel) {
        updatedPanel.gridAttributes = this.convertToGridAttributes(item);
        this.emitChange();
      }
    },
    emitChange() {
      this.$emit('input', this.dashboard);
    },
    convertToGridAttributes(gridStackProperties) {
      return {
        yPos: gridStackProperties.y,
        xPos: gridStackProperties.x,
        width: gridStackProperties.w,
        height: gridStackProperties.h,
      };
    },
  },
};
</script>

<template>
  <div>
    <div class="grid-stack" data-testid="gridstack-grid">
      <div
        v-for="panel in dashboard.panels"
        :id="panel.id"
        :key="panel.id"
        :gs-id="panel.id"
        :gs-x="getGridAttribute(panel, 'xPos')"
        :gs-y="getGridAttribute(panel, 'yPos')"
        :gs-h="getGridAttribute(panel, 'height')"
        :gs-w="getGridAttribute(panel, 'width')"
        :gs-min-h="getGridAttribute(panel, 'minHeight')"
        :gs-min-w="getGridAttribute(panel, 'minWidth')"
        :gs-max-h="getGridAttribute(panel, 'maxHeight')"
        :gs-max-w="getGridAttribute(panel, 'maxWidth')"
        class="grid-stack-item"
        :class="{ 'gl-cursor-grab': editing }"
        data-testid="grid-stack-panel"
      >
        <slot name="panel" v-bind="{ panel, editing, deletePanel }"></slot>
      </div>
    </div>
    <slot name="drawer" v-bind="{ addPanels }"></slot>
  </div>
</template>

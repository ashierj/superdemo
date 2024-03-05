import { nextTick } from 'vue';
import { GridStack } from 'gridstack';
import { breakpoints } from '@gitlab/ui/dist/utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GridstackWrapper from 'ee/vue_shared/components/customizable_dashboard/gridstack_wrapper.vue';
import {
  GRIDSTACK_MARGIN,
  GRIDSTACK_CSS_HANDLE,
  GRIDSTACK_CELL_HEIGHT,
  GRIDSTACK_MIN_ROW,
} from 'ee/vue_shared/components/customizable_dashboard/constants';
import { loadCSSFile } from '~/lib/utils/css_utils';
import waitForPromises from 'helpers/wait_for_promises';
import { createNewVisualizationPanel } from 'ee/analytics/analytics_dashboards/utils';
import { dashboard, builtinDashboard } from './mock_data';

const mockGridSetStatic = jest.fn();
const mockGridDestroy = jest.fn();
jest.mock('gridstack', () => ({
  GridStack: {
    init: jest.fn(() => {
      return {
        on: jest.fn(),
        destroy: mockGridDestroy,
        makeWidget: jest.fn(),
        setStatic: mockGridSetStatic,
        removeWidget: jest.fn(),
      };
    }),
  },
}));

jest.mock('~/lib/utils/css_utils', () => ({
  loadCSSFile: jest.fn(),
}));

describe('GridstackWrapper', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;
  let panelSlots = [];
  let drawerSlot;

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(GridstackWrapper, {
      propsData: {
        value: dashboard,
        ...props,
      },
      scopedSlots: {
        panel(data) {
          panelSlots.push(data);
        },
        drawer(data) {
          drawerSlot = data;
        },
      },
    });
  };

  const findGridStackPanels = () => wrapper.findAllByTestId('grid-stack-panel');
  const findPanelById = (panelId) => wrapper.find(`#${panelId}`);

  afterEach(() => {
    mockGridSetStatic.mockReset();
    mockGridDestroy.mockReset();

    panelSlots = [];
  });

  describe('default behaviour', () => {
    beforeEach(() => {
      loadCSSFile.mockResolvedValue();
      createWrapper();
    });

    it('sets up GridStack', () => {
      expect(GridStack.init).toHaveBeenCalledWith({
        alwaysShowResizeHandle: true,
        staticGrid: true,
        animate: false,
        margin: GRIDSTACK_MARGIN,
        handle: GRIDSTACK_CSS_HANDLE,
        cellHeight: GRIDSTACK_CELL_HEIGHT,
        minRow: GRIDSTACK_MIN_ROW,
        columnOpts: { breakpoints: [{ w: breakpoints.md, c: 1 }] },
      });
    });

    it('does not render the grab cursor on grid panels', () => {
      expect(findGridStackPanels().at(0).classes()).not.toContain('gl-cursor-grab');
    });

    it('passes data to drawer slot', () => {
      expect(drawerSlot).toStrictEqual({
        addPanels: expect.any(Function),
      });
    });

    describe.each(dashboard.panels.map((panel, index) => [panel, index]))(
      'for dashboard panel %#',
      (panel, index) => {
        it('renders a grid panel', () => {
          const element = findGridStackPanels().at(index);

          expect(element.attributes()).toMatchObject({
            'gs-id': expect.stringContaining('panel-'),
            'gs-h': `${panel.gridAttributes.height}`,
            'gs-w': `${panel.gridAttributes.width}`,
          });
        });

        it('passes data to the panel slot', () => {
          expect(panelSlots[index]).toStrictEqual({
            panel: {
              ...dashboard.panels[index],
              id: expect.stringContaining('panel-'),
            },
            editing: false,
            deletePanel: expect.any(Function),
          });
        });
      },
    );
  });

  describe('when editing = true', () => {
    beforeEach(() => {
      loadCSSFile.mockResolvedValue();
      createWrapper({ editing: true });

      return waitForPromises();
    });

    it('initializes GridStack with staticGrid = false', () => {
      expect(GridStack.init).toHaveBeenCalledWith(
        expect.objectContaining({
          staticGrid: false,
        }),
      );
    });

    it('calls GridStack.setStatic when the editing prop changes', async () => {
      wrapper.setProps({ editing: false });

      await nextTick();

      expect(mockGridSetStatic).toHaveBeenCalledWith(true);
    });

    it('renders the grab cursor on grid panels', () => {
      expect(findGridStackPanels().at(0).classes()).toContain('gl-cursor-grab');
    });
  });

  describe('when a panel is updated', () => {
    let gridPanel;

    beforeEach(() => {
      loadCSSFile.mockResolvedValue();
      createWrapper();

      gridPanel = findGridStackPanels().at(0);

      wrapper.vm.updatePanelWithGridStackItem({
        id: gridPanel.attributes('id'),
        x: 10,
        y: 20,
        w: 30,
        h: 40,
      });
    });

    it('updates the panels grid attributes', () => {
      expect(gridPanel.attributes()).toMatchObject({
        'gs-h': '40',
        'gs-w': '30',
        'gs-x': '10',
        'gs-y': '20',
      });
    });

    it('emits the changed dashboard object', () => {
      expect(wrapper.emitted('input')).toMatchObject([
        [
          {
            ...dashboard,
            panels: [
              {
                ...dashboard.panels[0],
                gridAttributes: {
                  xPos: 10,
                  yPos: 20,
                  width: 30,
                  height: 40,
                },
              },
              ...dashboard.panels.slice(1),
            ],
          },
        ],
      ]);
    });
  });

  describe('when panels are added', () => {
    let newPanel;

    beforeEach(() => {
      loadCSSFile.mockResolvedValue();
      createWrapper();

      newPanel = createNewVisualizationPanel(builtinDashboard.panels[0].visualization);
    });

    it('adds panels to the dashboard', async () => {
      expect(findGridStackPanels().length).toEqual(2);
      expect(findPanelById(newPanel.id).exists()).toBe(false);

      drawerSlot.addPanels([newPanel]);
      await nextTick();

      expect(findGridStackPanels().length).toEqual(3);
      expect(findPanelById(newPanel.id).exists()).toBe(true);
    });

    it('emits the changed dashboard object', async () => {
      drawerSlot.addPanels([newPanel]);
      await nextTick();

      expect(wrapper.emitted('input')).toMatchObject([
        [
          {
            ...dashboard,
            panels: [...dashboard.panels, newPanel],
          },
        ],
      ]);
    });
  });

  describe('when a panel is deleted', () => {
    let removePanel;

    beforeEach(() => {
      loadCSSFile.mockResolvedValue();
      createWrapper();

      removePanel = panelSlots[0].panel;
    });

    it('should remove the panel from the dashboard', async () => {
      expect(findGridStackPanels().length).toEqual(2);
      expect(findPanelById(removePanel.id).exists()).toBe(true);

      panelSlots[0].deletePanel(removePanel);
      await nextTick();

      expect(findGridStackPanels().length).toEqual(1);
      expect(findPanelById(removePanel.id).exists()).toBe(false);
    });

    it('emits the changed dashboard object', async () => {
      panelSlots[0].deletePanel(removePanel);
      await nextTick();

      expect(wrapper.emitted('input')).toMatchObject([
        [
          {
            ...dashboard,
            panels: dashboard.panels.slice(1),
          },
        ],
      ]);
    });
  });

  describe('when an error occurs while loading the CSS', () => {
    const sentryError = new Error('Network error');

    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException');
      loadCSSFile.mockRejectedValue(sentryError);

      createWrapper();

      return waitForPromises();
    });

    it('reports the error to sentry', () => {
      expect(Sentry.captureException.mock.calls[0][0]).toStrictEqual(sentryError);
    });
  });

  describe('beforeDestroy', () => {
    beforeEach(async () => {
      loadCSSFile.mockResolvedValue();
      createWrapper();

      await waitForPromises();

      wrapper.destroy();
    });

    it('cleans up the gridstack instance', () => {
      expect(mockGridDestroy).toHaveBeenCalled();
    });
  });
});

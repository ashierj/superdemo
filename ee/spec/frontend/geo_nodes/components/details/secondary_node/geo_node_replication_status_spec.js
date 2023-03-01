import { GlPopover, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoNodeReplicationStatus from 'ee/geo_nodes/components/details/secondary_node/geo_node_replication_status.vue';
import { REPLICATION_STATUS_UI, REPLICATION_PAUSE_URL } from 'ee/geo_nodes/constants';
import { MOCK_SECONDARY_NODE } from 'ee_jest/geo_nodes/mock_data';

describe('GeoNodeReplicationStatus', () => {
  let wrapper;

  const defaultProps = {
    node: MOCK_SECONDARY_NODE,
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(GeoNodeReplicationStatus, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findReplicationStatusText = () => wrapper.findByTestId('replication-status-text');
  const findQuestionIcon = () => wrapper.findComponent({ ref: 'replicationStatus' });
  const findGlPopover = () => wrapper.findComponent(GlPopover);
  const findGlPopoverLink = () => findGlPopover().findComponent(GlLink);

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the replication status text', () => {
        expect(findReplicationStatusText().exists()).toBe(true);
      });

      it('renders the question icon correctly', () => {
        expect(findQuestionIcon().exists()).toBe(true);
        expect(findQuestionIcon().attributes('name')).toBe('question-o');
      });

      it('renders the GlPopover always', () => {
        expect(findGlPopover().exists()).toBe(true);
      });

      it('renders the popover link correctly', () => {
        expect(findGlPopoverLink().exists()).toBe(true);
        expect(findGlPopoverLink().attributes('href')).toBe(REPLICATION_PAUSE_URL);
      });
    });

    describe.each`
      enabled  | uiData
      ${true}  | ${REPLICATION_STATUS_UI.enabled}
      ${false} | ${REPLICATION_STATUS_UI.disabled}
    `(`conditionally`, ({ enabled, uiData }) => {
      beforeEach(() => {
        createComponent({ node: { enabled } });
      });

      describe(`when enabled is ${enabled}`, () => {
        it(`renders the replication status text correctly`, () => {
          expect(findReplicationStatusText().classes(uiData.color)).toBe(true);
          expect(findReplicationStatusText().text()).toBe(uiData.text);
        });
      });
    });
  });
});

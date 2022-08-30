import timezoneMock from 'timezone-mock';
import { GlIcon, GlDropdown } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import IncidentTimelineEventItem from '~/issues/show/components/incidents/timeline_events_item.vue';
import { mockEvents } from './mock_data';

describe('IncidentTimelineEventList', () => {
  let wrapper;

  const mountComponent = ({ propsData, provide } = {}) => {
    const { action, noteHtml, occurredAt } = mockEvents[0];
    wrapper = mountExtended(IncidentTimelineEventItem, {
      propsData: {
        action,
        noteHtml,
        occurredAt,
        ...propsData,
      },
      provide: {
        canUpdate: false,
        ...provide,
      },
    });
  };

  const findCommentIcon = () => wrapper.findComponent(GlIcon);
  const findEventTime = () => wrapper.findByTestId('event-time');
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDeleteButton = () => wrapper.findByText('Delete');

  describe('template', () => {
    it('shows comment icon', () => {
      mountComponent();

      expect(findCommentIcon().exists()).toBe(true);
    });

    it('sets correct props for icon', () => {
      mountComponent();

      expect(findCommentIcon().props('name')).toBe(mockEvents[0].action);
    });

    it('displays the correct time', () => {
      mountComponent();

      expect(findEventTime().text()).toBe('15:59 UTC');
    });

    describe.each`
      timezone
      ${'Europe/London'}
      ${'US/Pacific'}
      ${'Australia/Adelaide'}
    `('when viewing in timezone', ({ timezone }) => {
      describe(timezone, () => {
        beforeEach(() => {
          timezoneMock.register(timezone);

          mountComponent();
        });

        afterEach(() => {
          timezoneMock.unregister();
        });

        it('displays the correct time', () => {
          expect(findEventTime().text()).toBe('15:59 UTC');
        });
      });
    });

    describe('action dropdown', () => {
      it('does not show the action dropdown by default', () => {
        mountComponent();

        expect(findDropdown().exists()).toBe(false);
        expect(findDeleteButton().exists()).toBe(false);
      });

      it('shows dropdown and delete item when user has update permission', () => {
        mountComponent({ provide: { canUpdate: true } });

        expect(findDropdown().exists()).toBe(true);
        expect(findDeleteButton().exists()).toBe(true);
      });

      it('triggers a delete when the delete button is clicked', async () => {
        mountComponent({ provide: { canUpdate: true } });

        findDeleteButton().trigger('click');

        await nextTick();

        expect(wrapper.emitted().delete).toBeTruthy();
      });
    });
  });
});

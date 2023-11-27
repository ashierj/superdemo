import { GlForm, GlBadge, GlCollapsibleListbox } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import WorkItemHealthStatus from 'ee/work_items/components/work_item_health_status_with_edit.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import {
  HEALTH_STATUS_AT_RISK,
  HEALTH_STATUS_I18N_NONE,
  HEALTH_STATUS_NEEDS_ATTENTION,
  HEALTH_STATUS_ON_TRACK,
  healthStatusTextMap,
} from 'ee/sidebar/constants';

import {
  updateWorkItemMutationResponse,
  workItemByIidResponseFactory,
} from 'jest/work_items/mock_data';

describe('WorkItemHealthStatus component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const workItemId = 'gid://gitlab/WorkItem/1';
  const workItemType = 'Task';
  const workItemQueryResponse = workItemByIidResponseFactory({ canUpdate: true, canDelete: true });
  const workItemQueryHandler = jest.fn().mockResolvedValue(workItemQueryResponse);

  const findHeader = () => wrapper.find('h3');
  const findEditButton = () => wrapper.find('[data-testid="edit-health-status"]');
  const findApplyButton = () => wrapper.find('[data-testid="apply-health-status"]');
  const findLabel = () => wrapper.find('label');
  const findForm = () => wrapper.findComponent(GlForm);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findBadge = () => wrapper.findComponent(GlBadge);

  const createComponent = ({
    canUpdate = true,
    hasIssuableHealthStatusFeature = true,
    isEditing = false,
    healthStatus,
    mutationHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse),
  } = {}) => {
    wrapper = mountExtended(WorkItemHealthStatus, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, workItemQueryHandler],
        [updateWorkItemMutation, mutationHandler],
      ]),
      propsData: {
        canUpdate,
        healthStatus,
        workItemId,
        workItemIid: '1',
        workItemType,
      },
      provide: {
        hasIssuableHealthStatusFeature,
      },
    });

    if (isEditing) {
      findEditButton().trigger('click');
    }
  };

  describe('`hasIssuableHealthStatusFeature` licensed feature', () => {
    describe.each`
      description             | hasIssuableHealthStatusFeature | exists
      ${'when available'}     | ${true}                        | ${true}
      ${'when not available'} | ${false}                       | ${false}
    `('$description', ({ hasIssuableHealthStatusFeature, exists }) => {
      it(`${hasIssuableHealthStatusFeature ? 'renders' : 'does not render'} component`, () => {
        createComponent({ hasIssuableHealthStatusFeature });

        expect(findHeader().exists()).toBe(exists);
      });
    });
  });

  describe('update permissions', () => {
    describe.each`
      description                     | canUpdate | exists
      ${'when allowed to update'}     | ${true}   | ${true}
      ${'when not allowed to update'} | ${false}  | ${false}
    `('$description', ({ canUpdate, exists }) => {
      it(`${canUpdate ? 'renders' : 'does not render'} the dropdown`, () => {
        createComponent({ canUpdate });

        expect(findEditButton().exists()).toBe(exists);
      });
    });
  });

  describe('label', () => {
    it('shows header when not editing', () => {
      createComponent();

      expect(findHeader().exists()).toBe(true);
      expect(findHeader().classes('gl-sr-only')).toBe(false);
      expect(findLabel().exists()).toBe(false);
    });

    it('shows label and hides header while editing', async () => {
      createComponent({ isEditing: true });

      await nextTick();

      expect(findLabel().exists()).toBe(true);
      expect(findHeader().classes('gl-sr-only')).toBe(true);
    });
  });

  describe('edit button', () => {
    it('is not shown if user cannot edit', () => {
      createComponent({ canUpdate: false });

      expect(findEditButton().exists()).toBe(false);
    });

    it('is shown if user can edit', () => {
      createComponent({ canUpdate: true });

      expect(findEditButton().exists()).toBe(true);
    });

    it('triggers edit mode on click', async () => {
      createComponent();

      findEditButton().trigger('click');

      await nextTick();

      expect(findLabel().exists()).toBe(true);
      expect(findForm().exists()).toBe(true);
    });

    it('is replaced by Apply button while editing', async () => {
      createComponent();

      findEditButton().trigger('click');

      await nextTick();

      expect(findEditButton().exists()).toBe(false);
      expect(findApplyButton().exists()).toBe(true);
    });
  });

  describe('health status rendering', () => {
    describe('correct text', () => {
      it.each`
        healthStatus                     | text
        ${HEALTH_STATUS_ON_TRACK}        | ${healthStatusTextMap[HEALTH_STATUS_ON_TRACK]}
        ${HEALTH_STATUS_NEEDS_ATTENTION} | ${healthStatusTextMap[HEALTH_STATUS_NEEDS_ATTENTION]}
        ${HEALTH_STATUS_AT_RISK}         | ${healthStatusTextMap[HEALTH_STATUS_AT_RISK]}
        ${null}                          | ${HEALTH_STATUS_I18N_NONE}
      `('renders "$text" when health status = "$healthStatus"', ({ healthStatus, text }) => {
        createComponent({ healthStatus });

        expect(wrapper.text()).toContain(text);
      });
    });

    describe('badge renders correct variant', () => {
      it.each`
        healthStatus                     | variant
        ${HEALTH_STATUS_ON_TRACK}        | ${'success'}
        ${HEALTH_STATUS_NEEDS_ATTENTION} | ${'warning'}
        ${HEALTH_STATUS_AT_RISK}         | ${'danger'}
      `('uses "$variant" when health status = "$healthStatus"', ({ healthStatus, variant }) => {
        createComponent({ healthStatus });

        expect(findBadge().props('variant')).toBe(variant);
      });
    });
  });

  describe('form', () => {
    it('is not shown while not editing', async () => {
      await createComponent();

      expect(findForm().exists()).toBe(false);
    });

    it('is shown while editing', async () => {
      await createComponent({ isEditing: true });

      expect(findForm().exists()).toBe(true);
    });
  });

  describe('health status input', () => {
    it('is not shown while not editing', async () => {
      await createComponent();

      expect(findListbox().exists()).toBe(false);
    });

    it.each`
      selected            | expectedStatus
      ${'empty'}          | ${null}
      ${'onTrack'}        | ${'onTrack'}
      ${'needsAttention'} | ${'needsAttention'}
      ${'atRisk'}         | ${'atRisk'}
    `(
      'calls mutation with health status = "$expectedStatus"',
      async ({ selected, expectedStatus }) => {
        const mutationSpy = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);
        await createComponent({
          isEditing: true,
          mutationHandler: mutationSpy,
        });

        await findListbox().vm.$emit('select', selected);

        expect(mutationSpy).toHaveBeenCalledWith({
          input: {
            id: workItemId,
            healthStatusWidget: {
              healthStatus: expectedStatus,
            },
          },
        });
      },
    );

    it('emits an error when there is a GraphQL error', async () => {
      const response = {
        data: {
          workItemUpdate: {
            errors: ['Error!'],
            workItem: {},
          },
        },
      };
      await createComponent({
        isEditing: true,
        mutationHandler: jest.fn().mockResolvedValue(response),
      });

      await findListbox().vm.$emit('select', 'onTrack');
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong while updating the task. Please try again.'],
      ]);
    });

    it('emits an error when there is a network error', async () => {
      await createComponent({
        isEditing: true,
        mutationHandler: jest.fn().mockRejectedValue(new Error()),
      });

      await findListbox().vm.$emit('select', 'onTrack');
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong while updating the task. Please try again.'],
      ]);
    });

    it('tracks updating the health status', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      await createComponent({ isEditing: true });

      await findListbox().vm.$emit('select', 'onTrack');

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'updated_health_status', {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_health_status',
        property: 'type_Task',
      });
    });
  });
});

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AddOnBulkActionConfirmationModal from 'ee/usage_quotas/code_suggestions/components/add_on_bulk_action_confirmation_modal.vue';

describe('Add On Bulk Action Confirmation Modal', () => {
  let wrapper;

  const GlModal = {
    template: `
      <div>
        <slot></slot>
        <slot name="modal-footer"></slot>
      </div>
    `,
  };

  const createComponent = (propsData = {}) => {
    wrapper = shallowMountExtended(AddOnBulkActionConfirmationModal, {
      propsData: {
        userCount: 1,
        bulkAction: 'ASSIGN_BULK_ACTION',
        ...propsData,
      },
      stubs: {
        GlModal,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findModalBodyText = () =>
    wrapper.findByTestId('bulk-action-confirmation-modal-body').text();
  const findAssignSeatsButton = () => wrapper.findByTestId('assign-confirmation-button');
  const findRemoveSeatsButton = () => wrapper.findByTestId('unassign-confirmation-button');
  const findCancelButton = () => wrapper.findByTestId('bulk-action-cancel-button');

  describe('when bulk action is for seat assignment', () => {
    it('renders modal with appropriate props', () => {
      createComponent();

      expect(findModalBodyText()).toBe(
        'This action will assign a GitLab Duo Pro seat to 1 user. Are you sure you want to continue?',
      );
      expect(findAssignSeatsButton().exists()).toBe(true);
      expect(findRemoveSeatsButton().exists()).toBe(false);
    });

    it('pluralises user count appropriately', () => {
      createComponent({
        userCount: 2,
      });

      expect(findModalBodyText()).toBe(
        'This action will assign a GitLab Duo Pro seat to 2 users. Are you sure you want to continue?',
      );
    });
  });

  describe('when bulk action is for seat unassignment', () => {
    it('renders modal with appropriate props', () => {
      createComponent({
        bulkAction: 'UNASSIGN_BULK_ACTION',
      });

      expect(findModalBodyText()).toBe(
        'This action will remove GitLab Duo Pro seat from 1 user. Are you sure you want to continue?',
      );
      expect(findRemoveSeatsButton().exists()).toBe(true);
      expect(findAssignSeatsButton().exists()).toBe(false);
    });

    it('pluralises user count appropriately', () => {
      createComponent({
        userCount: 2,
        bulkAction: 'UNASSIGN_BULK_ACTION',
      });

      expect(findModalBodyText()).toBe(
        'This action will remove GitLab Duo Pro seats from 2 users. Are you sure you want to continue?',
      );
    });
  });

  it('should emit cancel when cancel button is clicked', () => {
    createComponent();

    findCancelButton().vm.$emit('click');

    expect(wrapper.emitted('cancel')).toHaveLength(1);
  });

  it('should emit cancel when the hide event is emitted', () => {
    createComponent();

    findModal().vm.$emit('hide');

    expect(wrapper.emitted('cancel')).toHaveLength(1);
  });
});

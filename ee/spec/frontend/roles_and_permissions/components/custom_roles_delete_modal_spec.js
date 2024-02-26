import { GlModal } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import CustomRolesDeleteModal from 'ee/roles_and_permissions/components/custom_roles_delete_modal.vue';

describe('CustomRoleDeleteModal', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(CustomRolesDeleteModal, {
      propsData: {
        visible: false,
        ...props,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);

  describe('on creation', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders modal', () => {
      expect(findModal().exists()).toBe(true);

      expect(findModal().attributes('title')).toEqual('Delete custom role?');
      expect(findModal().text()).toBe(
        'Are you sure you want to delete this custom role? Before you delete this custom role, make sure no group member has this role.',
      );

      expect(findModal().props('actionPrimary')).toStrictEqual({
        text: 'Delete role',
        attributes: { variant: 'danger' },
      });
      expect(findModal().props('actionCancel')).toStrictEqual({
        text: 'Cancel',
      });
    });
  });

  describe('when the `primary` button is clicked', () => {
    beforeEach(async () => {
      createComponent({ props: { visible: true } });

      await nextTick();
    });

    it('emits `delete` event', () => {
      findModal().vm.$emit('primary');

      expect(wrapper.emitted('delete')).toHaveLength(1);
    });
  });

  describe('when the `cancel` button is clicked', () => {
    beforeEach(async () => {
      createComponent({ props: { visible: true } });

      await nextTick();
    });

    it('emits `cancel` event', () => {
      findModal().vm.$emit('hidden');

      expect(wrapper.emitted('cancel')).toHaveLength(1);
    });
  });
});

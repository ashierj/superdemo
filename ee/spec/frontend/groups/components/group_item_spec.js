import { shallowMount } from '@vue/test-utils';
import FrameworkBadge from 'ee_else_ce/compliance_dashboard/components/shared/framework_badge.vue';
import waitForPromises from 'helpers/wait_for_promises';
import GroupFolder from '~/groups/components/group_folder.vue';
import GroupItem from 'jh_else_ce/groups/components/group_item.vue';
import { mockParentGroupItem, mockChildren } from '../mock_data';

const createComponent = (props = {}) => {
  return shallowMount(GroupItem, {
    propsData: {
      parentGroup: mockParentGroupItem,
      ...props,
    },
    components: { GroupFolder },
    provide: {
      currentGroupVisibility: 'private',
    },
  });
};

describe('GroupItemComponent', () => {
  let wrapper;

  const findComplianceFrameworkBadge = () => wrapper.findComponent(FrameworkBadge);

  describe('Compliance framework label', () => {
    it('does not render if the item does not have a compliance framework', async () => {
      wrapper = createComponent({ group: mockChildren[0] });
      await waitForPromises();

      expect(findComplianceFrameworkBadge().exists()).toBe(false);
    });

    it('renders if the item has a compliance framework', async () => {
      wrapper = createComponent({ group: mockChildren[1] });
      await waitForPromises();

      expect(findComplianceFrameworkBadge().exists()).toBe(true);

      expect(findComplianceFrameworkBadge().props()).toMatchObject({
        framework: mockChildren[1].complianceFramework,
        showEdit: false,
        size: 'sm',
      });
    });
  });
});

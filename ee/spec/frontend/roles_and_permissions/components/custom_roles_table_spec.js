import { mountExtended } from 'helpers/vue_test_utils_helper';
import CustomRolesTable from 'ee/roles_and_permissions/components/custom_roles_table.vue';
import CustomRolesActions from 'ee/roles_and_permissions/components/custom_roles_actions.vue';
import { mockMemberRoles } from '../mock_data';

describe('CustomRolesTable', () => {
  let wrapper;

  const mockCustomRoles = mockMemberRoles.data.namespace.memberRoles.nodes;
  const mockCustomRole = mockCustomRoles[0];

  const createComponent = (props = {}) => {
    wrapper = mountExtended(CustomRolesTable, {
      propsData: {
        customRoles: mockCustomRoles,
        ...props,
      },
    });
  };

  const findHeaders = () => wrapper.find('thead').find('tr').findAll('th');
  const findCells = () => wrapper.findAllByRole('cell');
  const findActions = () => wrapper.findAllComponents(CustomRolesActions).at(0);

  beforeEach(() => {
    createComponent();
  });

  describe('on creation', () => {
    it('renders the header', () => {
      expect(findHeaders().at(0).text()).toBe('ID');
      expect(findHeaders().at(1).text()).toBe('Name');
      expect(findHeaders().at(2).text()).toBe('Description');
      expect(findHeaders().at(3).text()).toBe('Base role');
      expect(findHeaders().at(4).text()).toBe('Custom permissions');
      expect(findHeaders().at(5).text()).toBe('Member count');
      expect(findHeaders().at(6).text()).toBe('Actions');
    });

    it('renders the id', () => {
      expect(findCells().at(0).text()).toContain('1');
    });

    it('renders the name', () => {
      expect(findCells().at(1).text()).toContain('Test');
    });

    it('renders the description', () => {
      expect(findCells().at(2).text()).toContain('Test description');
    });

    it('renders the base access level', () => {
      expect(findCells().at(3).text()).toContain('Reporter');
    });

    it('renders the permissions', () => {
      expect(findCells().at(4).text()).toContain('Read code');
      expect(findCells().at(4).text()).toContain('Read vulnerability');
    });

    it('renders the member count', () => {
      expect(findCells().at(5).text()).toContain('0');
    });

    it('renders the actions', () => {
      expect(findActions().exists()).toBe(true);

      expect(findCells().at(6).text()).toContain('Edit role');
      expect(findCells().at(6).text()).toContain('Delete role');
    });
  });

  describe('when `delete` event is emitted', () => {
    beforeEach(async () => {
      await findActions().vm.$emit('delete');
    });

    it('emits `delete-role` event', () => {
      expect(wrapper.emitted('delete-role')).toEqual([[mockCustomRole]]);
    });
  });
});

import { mountExtended } from 'helpers/vue_test_utils_helper';
import CustomRolesTable from 'ee/roles_and_permissions/components/custom_roles_table.vue';
import { mockMemberRoles } from '../mock_data';

describe('CustomRolesTable', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(CustomRolesTable, {
      propsData: {
        customRoles: mockMemberRoles.data.namespace.memberRoles.nodes,
      },
    });
  };

  const findHeaders = () => wrapper.find('thead').find('tr').findAll('th');
  const findCells = () => wrapper.findAllByRole('cell');

  beforeEach(() => {
    createComponent();
  });

  it('renders the header', () => {
    expect(findHeaders().at(0).text()).toBe('ID');
    expect(findHeaders().at(1).text()).toBe('Name');
    expect(findHeaders().at(2).text()).toBe('Description');
    expect(findHeaders().at(3).text()).toBe('Base role');
    expect(findHeaders().at(4).text()).toBe('Custom permissions');
    expect(findHeaders().at(5).text()).toBe('Actions');
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

  it('renders the actions', () => {
    expect(findCells().at(5).text()).toContain('Edit role');
    expect(findCells().at(5).text()).toContain('Delete role');
  });
});

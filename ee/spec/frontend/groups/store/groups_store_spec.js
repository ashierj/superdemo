import GroupsStore from '~/groups/store/groups_store';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { mockRawChildren } from '../mock_data';

describe('ee/ProjectsStore', () => {
  describe('formatGroupItem', () => {
    it('without a compliance framework', () => {
      const store = new GroupsStore();
      const updatedGroupItem = store.formatGroupItem(mockRawChildren[0]);

      expect(updatedGroupItem.complianceFramework).toBeUndefined();
    });

    it('with a compliance framework', () => {
      const store = new GroupsStore();
      const updatedGroupItem = store.formatGroupItem(mockRawChildren[1]);

      expect(updatedGroupItem.complianceFramework).toStrictEqual({
        id: convertToGraphQLId(
          'ComplianceManagement::Framework',
          mockRawChildren[1].compliance_management_framework.id,
        ),
        name: mockRawChildren[1].compliance_management_framework.name,
        color: mockRawChildren[1].compliance_management_framework.color,
        description: mockRawChildren[1].compliance_management_framework.description,
      });
    });
  });
});

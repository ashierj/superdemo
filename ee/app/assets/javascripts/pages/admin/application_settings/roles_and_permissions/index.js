import { initRolesAndPermissions } from 'ee/roles_and_permissions';
import { s__ } from '~/locale';

initRolesAndPermissions({
  emptyText: s__(`MemberRole|To add a new role select a group and then 'Add new role'.`),
  showGroupSelector: true,
});

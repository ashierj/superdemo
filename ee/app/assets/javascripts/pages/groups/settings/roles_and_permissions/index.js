import { initRolesAndPermissions } from 'ee/roles_and_permissions';
import { I18N_EMPTY_TEXT_GROUP } from 'ee/roles_and_permissions/constants';

initRolesAndPermissions({ emptyText: I18N_EMPTY_TEXT_GROUP, showGroupSelector: false });

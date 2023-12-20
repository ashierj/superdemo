import { __, s__ } from '~/locale';

export const FIELDS = [
  {
    key: 'name',
    label: s__('MemberRole|Name'),
    sortable: true,
  },
  {
    key: 'id',
    label: s__('MemberRole|ID'),
    sortable: true,
  },
  {
    key: 'base_access_level',
    label: s__('MemberRole|Base role'),
    sortable: true,
  },
  {
    key: 'permissions',
    label: s__('MemberRole|Permissions'),
  },
  {
    key: 'actions',
    label: s__('MemberRole|Actions'),
  },
];

// Translations
export const I18N_ADD_NEW_ROLE = s__('MemberRole|Add new role');
export const I18N_CANCEL = __('Cancel');
export const I18N_CARD_TITLE = s__('MemberRole|Custom roles');
export const I18N_CREATION_SUCCESS = s__('MemberRole|Role successfully created.');
export const I18N_DELETE_ROLE = s__('MemberRole|Delete role');
export const I18N_DELETION_ERROR = s__('MemberRole|Failed to delete the role.');
export const I18N_DELETION_SUCCESS = s__('MemberRole|Role successfully deleted.');
export const I18N_EMPTY_TITLE = s__('MemberRole|No custom roles for this group');
export const I18N_EMPTY_TEXT_GROUP = s__("MemberRole|To add a new role select 'Add new role'.");
export const I18N_EMPTY_TEXT_ADMIN = s__(
  "MemberRole|To add a new role select a group and then 'Add new role'.",
);
export const I18N_FETCH_ERROR = s__('MemberRole|Failed to fetch roles.');
export const I18N_MEMBER_ROLE_PERMISSIONS_QUERY_ERROR = s__(
  'MemberRole|Could not fetch available permissions: %{message}',
);
export const I18N_LICENSE_ERROR = s__('MemberRole|Make sure the group is in the Ultimate tier.');
export const I18N_MODAL_TITLE = s__('MemberRole|Are you sure you want to delete this role?');
export const I18N_MODAL_WARNING = s__(
  `MemberRole|To delete the custom role make sure no group member has this custom role`,
);

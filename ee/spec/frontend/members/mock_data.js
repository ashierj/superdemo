import { member } from 'jest/members/mock_data';

export * from 'jest/members/mock_data';

export const bannedMember = {
  ...member,
  banned: true,
};

export const customRoles = [
  { baseAccessLevel: 20, name: 'custom role 3', memberRoleId: 103 },
  { baseAccessLevel: 10, name: 'custom role 1', memberRoleId: 101 },
  { baseAccessLevel: 10, name: 'custom role 2', memberRoleId: 102 },
];

export const customPermissions = [{ name: 'Read code' }, { name: 'Read vulnerability' }];

export const upgradedMember = {
  ...member,
  accessLevel: { integerValue: 10, stringValue: 'custom role 1', memberRoleId: 101 },
  customPermissions,
  customRoles,
};

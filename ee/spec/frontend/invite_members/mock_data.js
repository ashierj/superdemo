const generateSubscriptionData = ({
  isFreeGroup = false,
  subscriptionSeats = 1,
  maxSeatsUsed = 0,
  seatsInUse = 0,
  billedUserIds = [],
  billedUserEmails = [],
  excludeGuests = false,
} = {}) => ({
  isFreeGroup,
  subscriptionSeats,
  maxSeatsUsed,
  seatsInUse,
  billedUserIds,
  billedUserEmails,
  excludeGuests,
});

export const generateInvitedUsersData = ({
  isGuestRole = false,
  usersToInviteByEmail = [],
  usersToAddById = [],
} = {}) => ({
  isGuestRole,
  usersToInviteByEmail,
  usersToAddById,
});

export const freePlanSubsciption = generateSubscriptionData({ isFreeGroup: true });
export const oneFreeSeatSubscription = generateSubscriptionData();
export const noFreePlacesSubscription = generateSubscriptionData({
  maxSeatsUsed: 1,
  seatsInUse: 1,
  billedUserIds: [1],
  billedUserEmails: ['test@example'],
});
export const subscriptionWithOverage = generateSubscriptionData({
  maxSeatsUsed: 2,
  seatsInUse: 1,
  billedUserIds: [1],
  billedUserEmails: ['test@example'],
});
export const allowGuestsSubscription = generateSubscriptionData({
  maxSeatsUsed: 1,
  seatsInUse: 1,
  billedUserIds: [1],
  billedUserEmails: ['test@example'],
  excludeGuests: true,
});

export const mockGroupMemberRoles = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/3',
      memberRoles: {
        nodes: [
          {
            baseAccessLevel: {
              integerValue: 10,
              __typename: 'AccessLevel',
            },
            id: 'gid://gitlab/MemberRole/100',
            name: 'My role group 1',
            description: 'My role group 1 description',
            enabledPermissions: {
              nodes: [
                {
                  name: 'Read code',
                  value: 'READ_CODE',
                },
              ],
            },
            __typename: 'MemberRole',
          },
          {
            baseAccessLevel: {
              integerValue: 20,
              __typename: 'AccessLevel',
            },
            id: 'gid://gitlab/MemberRole/101',
            name: 'My role group 2',
            description: 'My role group 2 description',
            enabledPermissions: {
              nodes: [
                {
                  name: 'Read code',
                  value: 'READ_CODE',
                },
              ],
            },
            __typename: 'MemberRole',
          },
        ],
        __typename: 'MemberRoleConnection',
      },
      __typename: 'Group',
    },
  },
};

export const mockProjectMemberRoles = {
  data: {
    namespace: {
      id: 'gid://gitlab/Project/12',
      memberRoles: {
        nodes: [
          {
            baseAccessLevel: {
              integerValue: 10,
              stringValue: 'GUEST',
              __typename: 'AccessLevel',
            },
            id: 'gid://gitlab/MemberRole/103',
            name: 'My role project 1',
            description: 'My role project 1 description',
            enabledPermissions: {
              nodes: [
                {
                  name: 'Read code',
                  value: 'READ_CODE',
                },
              ],
            },
            __typename: 'MemberRole',
          },
        ],
        __typename: 'MemberRoleConnection',
      },
    },
  },
};

export const mockInstanceMemberRoles = {
  data: {
    memberRoles: {
      nodes: [
        {
          baseAccessLevel: {
            integerValue: 10,
            stringValue: 'GUEST',
            __typename: 'AccessLevel',
          },
          id: 'gid://gitlab/MemberRole/104',
          name: 'My role instance 1',
          description: 'My role instance 1 description',
          enabledPermissions: {
            nodes: [
              {
                name: 'Read code',
                value: 'READ_CODE',
              },
            ],
          },
          __typename: 'MemberRole',
        },
      ],
      __typename: 'MemberRoleConnection',
    },
  },
};

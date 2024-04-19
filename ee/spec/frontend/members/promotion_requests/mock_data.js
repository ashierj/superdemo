export const data = [
  {
    id: 1,
    createdAt: '2024-03-27T12:26:31.285Z',
    updatedAt: '2024-03-27T12:26:31.285Z',
    requestedBy: {
      name: 'Test Owner',
      webUrl: 'http://127.0.0.1:3000/testowner',
    },
    newAccessLevel: {
      stringValue: 'Developer',
      integerValue: 30,
      memberRoleId: null,
    },
    oldAccessLevel: {
      stringValue: 'Guest',
      integerValue: 10,
    },
    source: {
      id: 22,
      fullName: 'Gitlab Org',
      webUrl: 'http://127.0.0.1:3000/groups/gitlab-org',
    },
    user: {
      id: 42,
      username: 'testguest',
      name: 'Test Guest',
      locked: false,
      avatarUrl:
        'https://www.gravatar.com/avatar/98df8d46f118f8bef552b0ec0a3d729466a912577830212a844b73960777ac56?s=80&d=identicon',
      webUrl: 'http://127.0.0.1:3000/testguest',
      showStatus: false,
      createdAt: '2023-11-08T22:02:40.139Z',
      lastActivityOn: null,
      blocked: false,
      isBot: false,
      oncallSchedules: [],
      escalationPolicies: [],
      email: 'testguest@example.com',
    },
  },
];

export const pagination = {
  currentPage: 1,
  perPage: 50,
  totalItems: 1,
  paramName: 'promotion_requests_page',
  params: {
    page: null,
  },
};

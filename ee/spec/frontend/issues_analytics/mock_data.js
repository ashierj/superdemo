import { TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';

const mockIteration = {
  title: 'Iteration 1',
  __typename: 'Iteration',
};

const mockLabels = {
  count: 1,
  nodes: [
    {
      id: 'gid://gitlab/GroupLabel/25',
      color: '#5fa752',
      title: 'label',
      description: null,
      __typename: 'Label',
    },
  ],
  __typename: 'LabelConnection',
};

const createIssue = (values) => {
  return {
    state: values.state ?? 'closed',
    epic: {
      iid: 12345,
      __typename: 'Epic',
    },
    labels: {
      count: 0,
      nodes: [],
      __typename: 'LabelConnection',
    },
    milestone: {
      title: '11.1',
      __typename: 'Milestone',
    },
    iteration: null,
    weight: '3',
    dueDate: '2020-10-08',
    assignees: {
      count: 0,
      nodes: [],
      __typename: 'UserCoreConnection',
    },
    author: {
      name: 'Administrator',
      webUrl: 'link-to-author',
      avatarUrl: 'link-to-avatar',
      __typename: 'UserCore',
    },
    webUrl: `issues/${values.iid}`,
    iid: values.iid,
    ...values,
    __typename: 'Issue',
  };
};

export const mockIssuesApiResponse = [
  createIssue({ iid: 12345, title: 'Issue-1', createdAt: '2020-01-08' }),
  createIssue({
    iid: 23456,
    state: 'opened',
    title: 'Issue-2',
    createdAt: '2020-01-07',
    labels: mockLabels,
  }),
  createIssue({
    iid: 34567,
    state: 'opened',
    title: 'Issue-3',
    createdAt: '2020-01-6',
    iteration: mockIteration,
  }),
  createIssue({
    iid: 34567,
    state: 'locked',
    title: 'Issue-3',
    createdAt: '2020-01-6',
    iteration: mockIteration,
  }),
];

export const tableHeaders = [
  'Issue',
  'Age',
  'Status',
  'Milestone',
  'Iteration',
  'Weight',
  'Due date',
  'Assignees',
  'Created by',
];

export const getQueryIssuesAnalyticsResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/22',
      issues: {
        count: 3,
        nodes: mockIssuesApiResponse,
        __typename: 'IssueConnection',
      },
      __typename: 'Group',
    },
  },
};

export const mockIssuesAnalyticsCountsStartDate = new Date('2023-07-04T00:00:00.000Z');
export const mockIssuesAnalyticsCountsEndDate = new Date('2023-09-15T00:00:00.000Z');

export const getMockIssuesAnalyticsCountsQuery = ({
  queryAlias,
  metricType,
  isProject = false,
} = {}) => `query get${queryAlias}($fullPath: ID!, $assigneeUsernames: [String!], $authorUsername: String, $milestoneTitle: String, $labelNames: [String!], $epicId: ID, $iterationId: ID, $myReactionEmoji: String, $weight: Int, $not: NegatedValueStreamAnalyticsIssueFilterInput) {
  namespace: ${isProject ? 'project' : 'group'}(fullPath: $fullPath) {
    id
    ${queryAlias}: flowMetrics {
      Jul_2023: ${metricType}(
        from: "2023-07-04"
        to: "2023-08-01"
        assigneeUsernames: $assigneeUsernames
        authorUsername: $authorUsername
        milestoneTitle: $milestoneTitle
        labelNames: $labelNames
        epicId: $epicId
        iterationId: $iterationId
        myReactionEmoji: $myReactionEmoji
        weight: $weight
        not: $not
      ) {
        value
      }
      Aug_2023: ${metricType}(
        from: "2023-08-01"
        to: "2023-09-01"
        assigneeUsernames: $assigneeUsernames
        authorUsername: $authorUsername
        milestoneTitle: $milestoneTitle
        labelNames: $labelNames
        epicId: $epicId
        iterationId: $iterationId
        myReactionEmoji: $myReactionEmoji
        weight: $weight
        not: $not
      ) {
        value
      }
      Sep_2023: ${metricType}(
        from: "2023-09-01"
        to: "2023-09-15"
        assigneeUsernames: $assigneeUsernames
        authorUsername: $authorUsername
        milestoneTitle: $milestoneTitle
        labelNames: $labelNames
        epicId: $epicId
        iterationId: $iterationId
        myReactionEmoji: $myReactionEmoji
        weight: $weight
        not: $not
      ) {
        value
      }
    }
  }
}
`;

export const getMockIssuesOpenedCountsResponse = ({ isProject = false, isEmpty = false } = {}) => ({
  id: 'fake-id',
  issuesOpenedCounts: {
    Jul_2023: {
      value: isEmpty ? 0 : 134,
      __typename: 'ValueStreamAnalyticsMetric',
    },
    Aug_2023: {
      value: isEmpty ? 0 : 21,
      __typename: 'ValueStreamAnalyticsMetric',
    },
    Sep_2023: {
      value: isEmpty ? 0 : 11,
      __typename: 'ValueStreamAnalyticsMetric',
    },
    __typename: isProject
      ? 'ProjectValueStreamAnalyticsFlowMetrics'
      : 'GroupValueStreamAnalyticsFlowMetrics',
  },
  __typename: isProject ? TYPENAME_PROJECT : TYPENAME_GROUP,
});

export const getMockIssuesClosedCountsResponse = ({ isProject = false, isEmpty = false } = {}) => ({
  id: 'fake-id',
  issuesClosedCounts: {
    Jul_2023: {
      value: isEmpty ? 0 : 110,
      __typename: 'ValueStreamAnalyticsMetric',
    },
    Aug_2023: {
      value: isEmpty ? 0 : 1,
      __typename: 'ValueStreamAnalyticsMetric',
    },
    Sep_2023: {
      value: isEmpty ? 0 : 15,
      __typename: 'ValueStreamAnalyticsMetric',
    },
    __typename: isProject
      ? 'ProjectValueStreamAnalyticsFlowMetrics'
      : 'GroupValueStreamAnalyticsFlowMetrics',
  },
  __typename: isProject ? TYPENAME_PROJECT : TYPENAME_GROUP,
});

export const getMockTotalIssuesAnalyticsCountsResponse = (isProject = false) => ({
  ...getMockIssuesOpenedCountsResponse({ isProject }),
  ...getMockIssuesClosedCountsResponse({ isProject }),
});

export const mockGroupIssuesAnalyticsCountsResponseData = getMockTotalIssuesAnalyticsCountsResponse();

export const mockProjectIssuesAnalyticsCountsResponseData = getMockTotalIssuesAnalyticsCountsResponse(
  true,
);

export const mockIssuesAnalyticsCountsChartData = [
  {
    name: 'Opened',
    data: [134, 21, 11],
  },
  {
    name: 'Closed',
    data: [110, 1, 15],
  },
];

export const mockChartDateRangeData = [
  {
    fromDate: '2023-07-04',
    toDate: '2023-08-01',
    month: 'Jul',
    year: 2023,
  },
  {
    fromDate: '2023-08-01',
    toDate: '2023-09-01',
    month: 'Aug',
    year: 2023,
  },
  {
    fromDate: '2023-09-01',
    toDate: '2023-09-15',
    month: 'Sep',
    year: 2023,
  },
];

export const mockOriginalFilters = {
  author_username: 'root',
  assignee_username: ['bob', 'smith'],
  label_name: ['Brest', 'DLT'],
  milestone_title: '16.4',
};

export const mockFilters = {
  authorUsername: 'root',
  assigneeUsernames: ['bob', 'smith'],
  labelName: ['Brest', 'DLT'],
  milestoneTitle: '16.4',
};

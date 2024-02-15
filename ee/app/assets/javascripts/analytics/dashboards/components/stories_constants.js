const doraPerformanceScoresProjectsCount = 60;

const doraPerformersScoreResponseData = [
  {
    __typename: 'DoraPerformanceScoreCount',
    metricName: 'deployment_frequency',
    lowProjectsCount: 9,
    mediumProjectsCount: 10,
    highProjectsCount: 40,
    noDataProjectsCount: 1,
  },
  {
    __typename: 'DoraPerformanceScoreCount',
    metricName: 'lead_time_for_changes',
    lowProjectsCount: 9,
    mediumProjectsCount: 20,
    highProjectsCount: 30,
    noDataProjectsCount: 1,
  },
  {
    __typename: 'DoraPerformanceScoreCount',
    metricName: 'time_to_restore_service',
    lowProjectsCount: 20,
    mediumProjectsCount: 20,
    highProjectsCount: 15,
    noDataProjectsCount: 5,
  },
  {
    __typename: 'DoraPerformanceScoreCount',
    metricName: 'change_failure_rate',
    lowProjectsCount: 25,
    mediumProjectsCount: 20,
    highProjectsCount: 10,
    noDataProjectsCount: 5,
  },
];

const doraPerformersScoreEmptyResponseData = [
  {
    __typename: 'DoraPerformanceScoreCount',
    metricName: 'deployment_frequency',
    lowProjectsCount: null,
    mediumProjectsCount: null,
    highProjectsCount: null,
    noDataProjectsCount: doraPerformanceScoresProjectsCount,
  },
  {
    __typename: 'DoraPerformanceScoreCount',
    metricName: 'lead_time_for_changes',
    lowProjectsCount: null,
    mediumProjectsCount: null,
    highProjectsCount: null,
    noDataProjectsCount: doraPerformanceScoresProjectsCount,
  },
  {
    __typename: 'DoraPerformanceScoreCount',
    metricName: 'time_to_restore_service',
    lowProjectsCount: null,
    mediumProjectsCount: null,
    highProjectsCount: null,
    noDataProjectsCount: doraPerformanceScoresProjectsCount,
  },
  {
    __typename: 'DoraPerformanceScoreCount',
    metricName: 'change_failure_rate',
    lowProjectsCount: null,
    mediumProjectsCount: null,
    highProjectsCount: null,
    noDataProjectsCount: doraPerformanceScoresProjectsCount,
  },
];

export const doraPerformanceScoreCountsSuccess = {
  data: {
    namespace: {
      id: 'fake-dora-performance-score-counts-request',
      doraPerformanceScoreCounts: {
        totalProjectsCount: doraPerformanceScoresProjectsCount,
        noDoraDataProjectsCount: 0,
        nodes: doraPerformersScoreResponseData,
      },
    },
  },
};

export const excludedProjectsDoraPerformanceScoreCounts = {
  data: {
    namespace: {
      id: 'fake-dora-performance-score-counts-request',
      doraPerformanceScoreCounts: {
        totalProjectsCount: doraPerformanceScoresProjectsCount,
        noDoraDataProjectsCount: 20,
        nodes: doraPerformersScoreResponseData,
      },
    },
  },
};

export const noProjectsWithDoraPerformanceScoreCounts = {
  data: {
    namespace: {
      id: 'fake-dora-performance-score-counts-request',
      doraPerformanceScoreCounts: {
        totalProjectsCount: doraPerformanceScoresProjectsCount,
        noDoraDataProjectsCount: doraPerformanceScoresProjectsCount,
        nodes: doraPerformersScoreEmptyResponseData,
      },
    },
  },
};

export const filterProjectTopics = ['ruby', 'vue.js'];

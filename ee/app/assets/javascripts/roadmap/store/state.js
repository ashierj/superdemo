export default () => ({
  // API Calls
  epicsState: '',
  progressTracking: '',
  isProgressTrackingActive: true,
  filterParams: null,
  isShowingMilestones: true,
  milestonesType: '',
  isShowingLabels: false,

  // Data
  epicIid: '',
  epics: [],
  pageInfo: null,
  visibleEpics: [],
  epicIds: [],
  fullPath: '',
  timeframe: [],
  presetType: '',
  timeframeRangeType: '',
  sortedBy: '',
  bufferSize: 0,

  // UI Flags
  hasFiltersApplied: false,
  epicsFetchInProgress: false,
  epicsFetchForTimeframeInProgress: false,
  epicsFetchForNextPageInProgress: false,
  epicsFetchFailure: false,
  epicsFetchResultEmpty: false,
});

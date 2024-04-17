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
  timeframe: [],
  presetType: '',
  timeframeRangeType: '',
  sortedBy: '',
  bufferSize: 0,

  // UI Flags
  hasFiltersApplied: false,
});

/**
 * Refresh user counts (and broadcast if open)
 */
export function refreshUserMergeRequestCounts() {
  // The new sidebar manages _all_ the counts in
  document.dispatchEvent(new CustomEvent('userCounts:fetch'));
  return Promise.resolve();
}

import Vue from 'vue';
import {
  setCookie,
  handleLocationHash,
  historyPushState,
  scrollToElement,
} from '~/lib/utils/common_utils';
import { createAlert, VARIANT_WARNING } from '~/alert';
import axios from '~/lib/utils/axios_utils';

import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';
import { mergeUrlParams, getLocationHash } from '~/lib/utils/url_utility';
import notesEventHub from '~/notes/event_hub';
import { generateTreeList } from '~/diffs/utils/tree_worker_utils';
import { sortTree } from '~/ide/stores/utils';
import { containsSensitiveToken, confirmSensitiveAction } from '~/lib/utils/secret_detection';
import {
  PARALLEL_DIFF_VIEW_TYPE,
  INLINE_DIFF_VIEW_TYPE,
  DIFF_VIEW_COOKIE_NAME,
  MR_TREE_SHOW_KEY,
  TREE_LIST_STORAGE_KEY,
  TREE_LIST_WIDTH_STORAGE_KEY,
  OLD_LINE_KEY,
  NEW_LINE_KEY,
  TYPE_KEY,
  MAX_RENDERING_DIFF_LINES,
  MAX_RENDERING_BULK_ROWS,
  MIN_RENDERING_MS,
  START_RENDERING_INDEX,
  INLINE_DIFF_LINES_KEY,
  DIFF_FILE_MANUAL_COLLAPSE,
  DIFF_FILE_AUTOMATIC_COLLAPSE,
  EVT_PERF_MARK_FILE_TREE_START,
  EVT_PERF_MARK_FILE_TREE_END,
  EVT_PERF_MARK_DIFF_FILES_START,
  TRACKING_CLICK_DIFF_VIEW_SETTING,
  TRACKING_DIFF_VIEW_INLINE,
  TRACKING_DIFF_VIEW_PARALLEL,
  TRACKING_CLICK_FILE_BROWSER_SETTING,
  TRACKING_FILE_BROWSER_TREE,
  TRACKING_FILE_BROWSER_LIST,
  TRACKING_CLICK_WHITESPACE_SETTING,
  TRACKING_WHITESPACE_SHOW,
  TRACKING_WHITESPACE_HIDE,
  TRACKING_CLICK_SINGLE_FILE_SETTING,
  TRACKING_SINGLE_FILE_MODE,
  TRACKING_MULTIPLE_FILES_MODE,
  EVT_MR_PREPARED,
  FILE_DIFF_POSITION_TYPE,
  EVT_DISCUSSIONS_ASSIGNED,
} from '../constants';
import {
  DISCUSSION_SINGLE_DIFF_FAILED,
  LOAD_SINGLE_DIFF_FAILED,
  BUILDING_YOUR_MR,
  SOMETHING_WENT_WRONG,
  ERROR_LOADING_FULL_DIFF,
  ERROR_DISMISSING_SUGESTION_POPOVER,
} from '../i18n';
import eventHub from '../event_hub';
import { markFileReview, setReviewsForMergeRequest } from '../utils/file_reviews';
import { getDerivedMergeRequestInformation } from '../utils/merge_request';
import { queueRedisHllEvents } from '../utils/queue_events';
import * as types from './mutation_types';
import {
  getDiffPositionByLineCode,
  getNoteFormData,
  convertExpandLines,
  idleCallback,
  allDiscussionWrappersExpanded,
  prepareLineForRenamedFile,
  parseUrlHashAsFileHash,
  isUrlHashNoteLink,
} from './utils';

export const setBaseConfig = ({ commit }, options) => {
  const {
    endpoint,
    endpointMetadata,
    endpointBatch,
    endpointDiffForPath,
    endpointCoverage,
    endpointUpdateUser,
    projectPath,
    dismissEndpoint,
    showSuggestPopover,
    defaultSuggestionCommitMessage,
    viewDiffsFileByFile,
    mrReviews,
    diffViewType,
    perPage,
  } = options;
  commit(types.SET_BASE_CONFIG, {
    endpoint,
    endpointMetadata,
    endpointBatch,
    endpointDiffForPath,
    endpointCoverage,
    endpointUpdateUser,
    projectPath,
    dismissEndpoint,
    showSuggestPopover,
    defaultSuggestionCommitMessage,
    viewDiffsFileByFile,
    mrReviews,
    diffViewType,
    perPage,
  });

  Array.from(new Set(Object.values(mrReviews).flat())).forEach((id) => {
    const viewedId = id.replace(/^hash:/, '');

    commit(types.SET_DIFF_FILE_VIEWED, { id: viewedId, seen: true });
  });
};

export const prefetchSingleFile = async ({ state, getters, commit }, treeEntry) => {
  const versionPath = state.mergeRequestDiff?.version_path;

  if (
    treeEntry &&
    !treeEntry.diffLoaded &&
    !treeEntry.diffLoading &&
    !getters.getDiffFileByHash(treeEntry.fileHash)
  ) {
    const urlParams = {
      old_path: treeEntry.filePaths.old,
      new_path: treeEntry.filePaths.new,
      w: state.showWhitespace ? '0' : '1',
      view: 'inline',
      commit_id: getters.commitId,
    };

    if (versionPath) {
      const { diffId, startSha } = getDerivedMergeRequestInformation({ endpoint: versionPath });

      urlParams.diff_id = diffId;
      urlParams.start_sha = startSha;
    }

    commit(types.TREE_ENTRY_DIFF_LOADING, { path: treeEntry.filePaths.new });

    try {
      const { data: diffData } = await axios.get(
        mergeUrlParams({ ...urlParams }, state.endpointDiffForPath),
      );

      commit(types.SET_DIFF_DATA_BATCH, { diff_files: diffData.diff_files });

      eventHub.$emit('diffFilesModified');
    } catch (e) {
      commit(types.TREE_ENTRY_DIFF_LOADING, { path: treeEntry.filePaths.new, loading: false });
    }
  }
};

export const fetchFileByFile = async ({ state, getters, commit }) => {
  const isNoteLink = isUrlHashNoteLink(window?.location?.hash);
  const id = parseUrlHashAsFileHash(window?.location?.hash, state.currentDiffFileId);
  const versionPath = state.mergeRequestDiff?.version_path;
  const treeEntry = id
    ? getters.flatBlobsList.find(({ fileHash }) => fileHash === id)
    : getters.flatBlobsList[0];

  eventHub.$emit(EVT_PERF_MARK_DIFF_FILES_START);

  if (treeEntry && !treeEntry.diffLoaded && !getters.getDiffFileByHash(id)) {
    // Overloading "batch" loading indicators so the UI stays mostly the same
    commit(types.SET_BATCH_LOADING_STATE, 'loading');
    commit(types.SET_RETRIEVING_BATCHES, true);

    const urlParams = {
      old_path: treeEntry.filePaths.old,
      new_path: treeEntry.filePaths.new,
      w: state.showWhitespace ? '0' : '1',
      view: 'inline',
      commit_id: getters.commitId,
    };

    if (versionPath) {
      const { diffId, startSha } = getDerivedMergeRequestInformation({ endpoint: versionPath });

      urlParams.diff_id = diffId;
      urlParams.start_sha = startSha;
    }

    axios
      .get(mergeUrlParams({ ...urlParams }, state.endpointDiffForPath))
      .then(({ data: diffData }) => {
        commit(types.SET_DIFF_DATA_BATCH, { diff_files: diffData.diff_files });

        if (!isNoteLink && !state.currentDiffFileId) {
          commit(types.SET_CURRENT_DIFF_FILE, state.diffFiles[0]?.file_hash || '');
        }

        commit(types.SET_BATCH_LOADING_STATE, 'loaded');

        eventHub.$emit('diffFilesModified');
      })
      .catch(() => {
        commit(types.SET_BATCH_LOADING_STATE, 'error');
      })
      .finally(() => {
        commit(types.SET_RETRIEVING_BATCHES, false);
      });
  }
};

export const fetchDiffFilesBatch = ({ commit, state, dispatch }) => {
  let perPage = state.viewDiffsFileByFile ? 1 : state.perPage;
  let increaseAmount = 1.4;
  const startPage = 0;
  const id = window?.location?.hash;
  const isNoteLink = id.indexOf('#note') === 0;
  const urlParams = {
    w: state.showWhitespace ? '0' : '1',
    view: 'inline',
  };
  const hash = window.location.hash.replace('#', '').split('diff-content-').pop();
  let totalLoaded = 0;
  let scrolledVirtualScroller = hash === '';

  commit(types.SET_BATCH_LOADING_STATE, 'loading');
  commit(types.SET_RETRIEVING_BATCHES, true);
  eventHub.$emit(EVT_PERF_MARK_DIFF_FILES_START);

  const getBatch = (page = startPage) =>
    axios
      .get(mergeUrlParams({ ...urlParams, page, per_page: perPage }, state.endpointBatch))
      .then(({ data: { pagination, diff_files: diffFiles } }) => {
        totalLoaded += diffFiles.length;

        commit(types.SET_DIFF_DATA_BATCH, { diff_files: diffFiles });
        commit(types.SET_BATCH_LOADING_STATE, 'loaded');

        if (!scrolledVirtualScroller) {
          const index = state.diffFiles.findIndex(
            (f) =>
              f.file_hash === hash || f[INLINE_DIFF_LINES_KEY].find((l) => l.line_code === hash),
          );

          if (index >= 0) {
            eventHub.$emit('scrollToIndex', index);
            scrolledVirtualScroller = true;
          }
        }

        if (!isNoteLink && !state.currentDiffFileId) {
          commit(types.SET_CURRENT_DIFF_FILE, diffFiles[0]?.file_hash);
        }

        if (isNoteLink) {
          dispatch('setCurrentDiffFileIdFromNote', id.split('_').pop());
        }

        if (totalLoaded === pagination.total_pages || pagination.total_pages === null) {
          commit(types.SET_RETRIEVING_BATCHES, false);
          eventHub.$emit('doneLoadingBatches');

          // We need to check that the currentDiffFileId points to a file that exists
          if (
            state.currentDiffFileId &&
            !state.diffFiles.some((f) => f.file_hash === state.currentDiffFileId) &&
            !isNoteLink
          ) {
            commit(types.SET_CURRENT_DIFF_FILE, state.diffFiles[0].file_hash);
          }

          if (state.diffFiles?.length) {
            // eslint-disable-next-line promise/catch-or-return,promise/no-nesting
            import('~/code_navigation').then((m) =>
              m.default({
                blobs: state.diffFiles
                  .filter((f) => f.code_navigation_path)
                  .map((f) => ({
                    path: f.new_path,
                    codeNavigationPath: f.code_navigation_path,
                  })),
                definitionPathPrefix: state.definitionPathPrefix,
              }),
            );
          }

          return null;
        }

        const nextPage = page + perPage;
        perPage = Math.min(Math.ceil(perPage * increaseAmount), 30);
        increaseAmount = Math.min(increaseAmount + 0.2, 2);

        return nextPage;
      })
      .then((nextPage) => {
        if (nextPage) {
          return getBatch(nextPage);
        }

        return null;
      })
      .catch(() => {
        commit(types.SET_RETRIEVING_BATCHES, false);
        commit(types.SET_BATCH_LOADING_STATE, 'error');
      });

  return getBatch();
};

export const fetchDiffFilesMeta = ({ commit, state }) => {
  const urlParams = {
    view: 'inline',
    w: state.showWhitespace ? '0' : '1',
  };

  commit(types.SET_LOADING, true);

  return axios
    .get(mergeUrlParams(urlParams, state.endpointMetadata))
    .then(({ data }) => {
      const strippedData = { ...data };
      delete strippedData.diff_files;

      commit(types.SET_LOADING, false);
      commit(types.SET_MERGE_REQUEST_DIFFS, data.merge_request_diffs || []);
      commit(types.SET_DIFF_METADATA, strippedData);

      eventHub.$emit(EVT_PERF_MARK_FILE_TREE_START);
      const { treeEntries, tree } = generateTreeList(data.diff_files);
      eventHub.$emit(EVT_PERF_MARK_FILE_TREE_END);
      commit(types.SET_TREE_DATA, {
        treeEntries,
        tree: sortTree(tree),
      });

      return data;
    })
    .catch((error) => {
      if (error.response.status === HTTP_STATUS_NOT_FOUND) {
        const alert = createAlert({
          message: BUILDING_YOUR_MR,
          variant: VARIANT_WARNING,
        });

        eventHub.$once(EVT_MR_PREPARED, () => alert.dismiss());
      } else {
        throw error;
      }
    });
};

export function prefetchFileNeighbors({ getters, dispatch }) {
  const { flatBlobsList: allBlobs, currentDiffIndex: currentIndex } = getters;

  const previous = Math.max(currentIndex - 1, 0);
  const next = Math.min(allBlobs.length - 1, currentIndex + 1);

  dispatch('prefetchSingleFile', allBlobs[next]);
  dispatch('prefetchSingleFile', allBlobs[previous]);
}

export const fetchCoverageFiles = ({ commit, state }) => {
  const coveragePoll = new Poll({
    resource: {
      getCoverageReports: (endpoint) => axios.get(endpoint),
    },
    data: state.endpointCoverage,
    method: 'getCoverageReports',
    successCallback: ({ status, data }) => {
      if (status === HTTP_STATUS_OK) {
        commit(types.SET_COVERAGE_DATA, data);

        coveragePoll.stop();
      }
    },
    errorCallback: () =>
      createAlert({
        message: SOMETHING_WENT_WRONG,
      }),
  });

  coveragePoll.makeRequest();
};

export const setHighlightedRow = ({ commit }, lineCode) => {
  const fileHash = lineCode.split('_')[0];
  commit(types.SET_HIGHLIGHTED_ROW, lineCode);
  commit(types.SET_CURRENT_DIFF_FILE, fileHash);

  handleLocationHash();
};

// This is adding line discussions to the actual lines in the diff tree
// once for parallel and once for inline mode
export const assignDiscussionsToDiff = (
  { commit, state, rootState, dispatch },
  discussions = rootState.notes.discussions,
) => {
  const id = window?.location?.hash;
  const isNoteLink = id.indexOf('#note') === 0;
  const diffPositionByLineCode = getDiffPositionByLineCode(state.diffFiles);
  const hash = getLocationHash();

  discussions
    .filter((discussion) => discussion.diff_discussion)
    .forEach((discussion) => {
      commit(types.SET_LINE_DISCUSSIONS_FOR_FILE, {
        discussion,
        diffPositionByLineCode,
        hash,
      });
    });

  if (isNoteLink) {
    dispatch('setCurrentDiffFileIdFromNote', id.split('_').pop());
  }

  Vue.nextTick(() => {
    eventHub.$emit(EVT_DISCUSSIONS_ASSIGNED);
  });
};

export const removeDiscussionsFromDiff = ({ commit }, removeDiscussion) => {
  const {
    diff_file: { file_hash: fileHash },
    line_code: lineCode,
    id,
  } = removeDiscussion;
  commit(types.REMOVE_LINE_DISCUSSIONS_FOR_FILE, { fileHash, lineCode, id });
};

export const toggleLineDiscussions = ({ commit }, options) => {
  commit(types.TOGGLE_LINE_DISCUSSIONS, options);
};

export const renderFileForDiscussionId = ({ commit, rootState, state }, discussionId) => {
  const discussion = rootState.notes.discussions.find((d) => d.id === discussionId);

  if (discussion && discussion.diff_file) {
    const file = state.diffFiles.find((f) => f.file_hash === discussion.diff_file.file_hash);

    if (file) {
      if (file.viewer.automaticallyCollapsed) {
        notesEventHub.$emit(`loadCollapsedDiff/${file.file_hash}`);
        scrollToElement(document.getElementById(file.file_hash));
      } else if (file.viewer.manuallyCollapsed) {
        commit(types.SET_FILE_COLLAPSED, {
          filePath: file.file_path,
          collapsed: false,
          trigger: DIFF_FILE_AUTOMATIC_COLLAPSE,
        });
        notesEventHub.$emit('scrollToDiscussion');
      } else {
        notesEventHub.$emit('scrollToDiscussion');
      }
    }
  }
};

export const setInlineDiffViewType = ({ commit }) => {
  commit(types.SET_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE);

  setCookie(DIFF_VIEW_COOKIE_NAME, INLINE_DIFF_VIEW_TYPE);
  const url = mergeUrlParams({ view: INLINE_DIFF_VIEW_TYPE }, window.location.href);
  historyPushState(url);

  queueRedisHllEvents([TRACKING_CLICK_DIFF_VIEW_SETTING, TRACKING_DIFF_VIEW_INLINE]);
};

export const setParallelDiffViewType = ({ commit }) => {
  commit(types.SET_DIFF_VIEW_TYPE, PARALLEL_DIFF_VIEW_TYPE);

  setCookie(DIFF_VIEW_COOKIE_NAME, PARALLEL_DIFF_VIEW_TYPE);
  const url = mergeUrlParams({ view: PARALLEL_DIFF_VIEW_TYPE }, window.location.href);
  historyPushState(url);

  queueRedisHllEvents([TRACKING_CLICK_DIFF_VIEW_SETTING, TRACKING_DIFF_VIEW_PARALLEL]);
};

export const showCommentForm = ({ commit }, { lineCode, fileHash }) => {
  commit(types.TOGGLE_LINE_HAS_FORM, { lineCode, fileHash, hasForm: true });

  // The comment form for diffs gets focussed differently due to the way the virtual scroller
  // works. If we focus the comment form on mount and the comment form gets removed and then
  // added again the page will scroll in unexpected ways
  setTimeout(() => {
    const el = document.querySelector(
      `[data-line-code="${lineCode}"] textarea, [data-line-code="${lineCode}"] [contenteditable="true"]`,
    );

    if (!el) return;

    const { bottom } = el.getBoundingClientRect();
    const overflowBottom = bottom - window.innerHeight;

    // Prevent the browser scrolling for us
    // We handle the scrolling to not break the diffs virtual scroller
    el.focus({ preventScroll: true });

    if (overflowBottom > 0) {
      window.scrollBy(0, Math.floor(Math.abs(overflowBottom)) + 150);
    }
  });
};

export const cancelCommentForm = ({ commit }, { lineCode, fileHash }) => {
  commit(types.TOGGLE_LINE_HAS_FORM, { lineCode, fileHash, hasForm: false });
};

export const loadMoreLines = ({ commit }, options) => {
  const { endpoint, params, lineNumbers, fileHash, isExpandDown, nextLineNumbers } = options;

  params.from_merge_request = true;

  return axios.get(endpoint, { params }).then((res) => {
    const contextLines = res.data || [];

    commit(types.ADD_CONTEXT_LINES, {
      lineNumbers,
      contextLines,
      params,
      fileHash,
      isExpandDown,
      nextLineNumbers,
    });
  });
};

export const scrollToLineIfNeededInline = (_, line) => {
  const hash = getLocationHash();

  if (hash && line.line_code === hash) {
    handleLocationHash();
  }
};

export const scrollToLineIfNeededParallel = (_, line) => {
  const hash = getLocationHash();

  if (
    hash &&
    ((line.left && line.left.line_code === hash) || (line.right && line.right.line_code === hash))
  ) {
    handleLocationHash();
  }
};

export const loadCollapsedDiff = ({ commit, getters, state }, { file, params = {} }) => {
  const versionPath = state.mergeRequestDiff?.version_path;
  const loadParams = {
    commit_id: getters.commitId,
    w: state.showWhitespace ? '0' : '1',
    ...params,
  };

  if (versionPath) {
    const { diffId, startSha } = getDerivedMergeRequestInformation({ endpoint: versionPath });

    loadParams.diff_id = diffId;
    loadParams.start_sha = startSha;
  }

  return axios.get(file.load_collapsed_diff_url, { params: loadParams }).then((res) => {
    commit(types.ADD_COLLAPSED_DIFFS, {
      file,
      data: res.data,
    });
  });
};

/**
 * Toggles the file discussions after user clicked on the toggle discussions button.
 *
 * Gets the discussions for the provided diff.
 *
 * If all discussions are expanded, it will collapse all of them
 * If all discussions are collapsed, it will expand all of them
 * If some discussions are open and others closed, it will expand the closed ones.
 *
 * @param {Object} diff
 */
export const toggleFileDiscussions = ({ getters, dispatch }, diff) => {
  const discussions = getters.getDiffFileDiscussions(diff);
  const shouldCloseAll = getters.diffHasAllExpandedDiscussions(diff);
  const shouldExpandAll = getters.diffHasAllCollapsedDiscussions(diff);

  discussions.forEach((discussion) => {
    const data = { discussionId: discussion.id };

    if (shouldCloseAll) {
      dispatch('collapseDiscussion', data, { root: true });
    } else if (shouldExpandAll || (!shouldCloseAll && !shouldExpandAll && !discussion.expanded)) {
      dispatch('expandDiscussion', data, { root: true });
    }
  });
};

export const toggleFileDiscussionWrappers = ({ commit }, diff) => {
  const discussionWrappersExpanded = allDiscussionWrappersExpanded(diff);
  const lineCodesWithDiscussions = new Set();
  const lineHasDiscussion = (line) => Boolean(line?.discussions.length);
  const registerDiscussionLine = (line) => lineCodesWithDiscussions.add(line.line_code);

  diff[INLINE_DIFF_LINES_KEY].filter(lineHasDiscussion).forEach(registerDiscussionLine);

  if (lineCodesWithDiscussions.size) {
    Array.from(lineCodesWithDiscussions).forEach((lineCode) => {
      commit(types.TOGGLE_LINE_DISCUSSIONS, {
        fileHash: diff.file_hash,
        expanded: !discussionWrappersExpanded,
        lineCode,
      });
    });
  }
};

export const saveDiffDiscussion = async ({ state, dispatch }, { note, formData }) => {
  const postData = getNoteFormData({
    commit: state.commit,
    note,
    showWhitespace: state.showWhitespace,
    ...formData,
  });

  if (containsSensitiveToken(note)) {
    const confirmed = await confirmSensitiveAction();
    if (!confirmed) {
      return null;
    }
  }

  return dispatch('saveNote', postData, { root: true })
    .then((result) => dispatch('updateDiscussion', result.discussion, { root: true }))
    .then((discussion) => dispatch('assignDiscussionsToDiff', [discussion]))
    .then(() => dispatch('updateResolvableDiscussionsCounts', null, { root: true }))
    .then(() => dispatch('closeDiffFileCommentForm', formData.diffFile.file_hash))
    .then(() => {
      if (formData.positionType === FILE_DIFF_POSITION_TYPE) {
        dispatch('toggleFileCommentForm', formData.diffFile.file_path);
      }
    });
};

export const toggleTreeOpen = ({ commit }, path) => {
  commit(types.TOGGLE_FOLDER_OPEN, path);
};

export const setCurrentFileHash = ({ commit }, hash) => {
  commit(types.SET_CURRENT_DIFF_FILE, hash);
};

export const goToFile = ({ state, commit, dispatch, getters }, { path }) => {
  if (!state.viewDiffsFileByFile) {
    dispatch('scrollToFile', { path });
  } else {
    if (!state.treeEntries[path]) return;

    const { fileHash } = state.treeEntries[path];

    commit(types.SET_CURRENT_DIFF_FILE, fileHash);
    document.location.hash = fileHash;

    if (!getters.isTreePathLoaded(path)) {
      dispatch('fetchFileByFile')
        .then(() => {
          dispatch('scrollToFile', { path });
        })
        .catch(() => {
          createAlert({
            message: LOAD_SINGLE_DIFF_FAILED,
          });
        });
    }
  }
};

export const scrollToFile = ({ state, commit, getters }, { path }) => {
  if (!state.treeEntries[path]) return;

  const { fileHash } = state.treeEntries[path];

  commit(types.SET_CURRENT_DIFF_FILE, fileHash);

  if (getters.isVirtualScrollingEnabled) {
    eventHub.$emit('scrollToFileHash', fileHash);

    setTimeout(() => {
      window.history.replaceState(null, null, `#${fileHash}`);
    });
  } else {
    document.location.hash = fileHash;

    setTimeout(() => {
      handleLocationHash();
    });
  }
};

export const setShowTreeList = ({ commit }, { showTreeList, saving = true }) => {
  commit(types.SET_SHOW_TREE_LIST, showTreeList);

  if (saving) {
    localStorage.setItem(MR_TREE_SHOW_KEY, showTreeList);
  }
};

export const toggleTreeList = ({ state, commit }) => {
  commit(types.SET_SHOW_TREE_LIST, !state.showTreeList);
};

export const openDiffFileCommentForm = ({ commit, getters }, formData) => {
  const form = getters.getCommentFormForDiffFile(formData.fileHash);

  if (form) {
    commit(types.UPDATE_DIFF_FILE_COMMENT_FORM, formData);
  } else {
    commit(types.OPEN_DIFF_FILE_COMMENT_FORM, formData);
  }
};

export const closeDiffFileCommentForm = ({ commit }, fileHash) => {
  commit(types.CLOSE_DIFF_FILE_COMMENT_FORM, fileHash);
};

export const setRenderTreeList = ({ commit }, { renderTreeList, trackClick = true }) => {
  commit(types.SET_RENDER_TREE_LIST, renderTreeList);

  localStorage.setItem(TREE_LIST_STORAGE_KEY, renderTreeList);

  if (trackClick) {
    const events = [TRACKING_CLICK_FILE_BROWSER_SETTING];

    if (renderTreeList) {
      events.push(TRACKING_FILE_BROWSER_TREE);
    } else {
      events.push(TRACKING_FILE_BROWSER_LIST);
    }

    queueRedisHllEvents(events);
  }
};

export const setShowWhitespace = async (
  { state, commit },
  { url, showWhitespace, updateDatabase = true, trackClick = true },
) => {
  if (updateDatabase && Boolean(window.gon?.current_user_id)) {
    await axios.put(url || state.endpointUpdateUser, { show_whitespace_in_diffs: showWhitespace });
  }

  commit(types.SET_SHOW_WHITESPACE, showWhitespace);
  notesEventHub.$emit('refetchDiffData');

  if (trackClick) {
    const events = [TRACKING_CLICK_WHITESPACE_SETTING];

    if (showWhitespace) {
      events.push(TRACKING_WHITESPACE_SHOW);
    } else {
      events.push(TRACKING_WHITESPACE_HIDE);
    }

    queueRedisHllEvents(events);
  }
};

export const toggleFileFinder = ({ commit }, visible) => {
  commit(types.TOGGLE_FILE_FINDER_VISIBLE, visible);
};

export const cacheTreeListWidth = (_, size) => {
  localStorage.setItem(TREE_LIST_WIDTH_STORAGE_KEY, size);
};

export const receiveFullDiffError = ({ commit }, filePath) => {
  commit(types.RECEIVE_FULL_DIFF_ERROR, filePath);
  createAlert({
    message: ERROR_LOADING_FULL_DIFF,
  });
};

export const setExpandedDiffLines = ({ commit }, { file, data }) => {
  const expandedDiffLines = convertExpandLines({
    diffLines: file[INLINE_DIFF_LINES_KEY],
    typeKey: TYPE_KEY,
    oldLineKey: OLD_LINE_KEY,
    newLineKey: NEW_LINE_KEY,
    data,
    mapLine: ({ line, oldLine, newLine }) =>
      Object.assign(line, {
        old_line: oldLine,
        new_line: newLine,
        line_code: `${file.file_hash}_${oldLine}_${newLine}`,
      }),
  });

  if (expandedDiffLines.length > MAX_RENDERING_DIFF_LINES) {
    let index = START_RENDERING_INDEX;
    commit(types.SET_CURRENT_VIEW_DIFF_FILE_LINES, {
      filePath: file.file_path,
      lines: expandedDiffLines.slice(0, index),
    });
    commit(types.TOGGLE_DIFF_FILE_RENDERING_MORE, file.file_path);

    const idleCb = (t) => {
      const startIndex = index;

      while (
        t.timeRemaining() >= MIN_RENDERING_MS &&
        index !== expandedDiffLines.length &&
        index - startIndex !== MAX_RENDERING_BULK_ROWS
      ) {
        const line = expandedDiffLines[index];

        if (line) {
          commit(types.ADD_CURRENT_VIEW_DIFF_FILE_LINES, { filePath: file.file_path, line });
          index += 1;
        }
      }

      if (index !== expandedDiffLines.length) {
        idleCallback(idleCb);
      } else {
        commit(types.TOGGLE_DIFF_FILE_RENDERING_MORE, file.file_path);
      }
    };

    idleCallback(idleCb);
  } else {
    commit(types.SET_CURRENT_VIEW_DIFF_FILE_LINES, {
      filePath: file.file_path,
      lines: expandedDiffLines,
    });
  }
};

export const fetchFullDiff = ({ commit, dispatch }, file) =>
  axios
    .get(file.context_lines_path, {
      params: {
        full: true,
        from_merge_request: true,
      },
    })
    .then(({ data }) => {
      commit(types.RECEIVE_FULL_DIFF_SUCCESS, { filePath: file.file_path });

      dispatch('setExpandedDiffLines', { file, data });
    })
    .catch(() => dispatch('receiveFullDiffError', file.file_path));

export const toggleFullDiff = ({ dispatch, commit, getters, state }, filePath) => {
  const file = state.diffFiles.find((f) => f.file_path === filePath);

  commit(types.REQUEST_FULL_DIFF, filePath);

  if (file.isShowingFullFile) {
    dispatch('loadCollapsedDiff', { file })
      .then(() => dispatch('assignDiscussionsToDiff', getters.getDiffFileDiscussions(file)))
      .catch(() => dispatch('receiveFullDiffError', filePath));
  } else {
    dispatch('fetchFullDiff', file);
  }
};

export function switchToFullDiffFromRenamedFile({ commit }, { diffFile }) {
  return axios
    .get(diffFile.context_lines_path, {
      params: {
        full: true,
        from_merge_request: true,
      },
    })
    .then(({ data }) => {
      const lines = data.map((line, index) =>
        prepareLineForRenamedFile({
          diffViewType: 'inline',
          line,
          diffFile,
          index,
        }),
      );

      commit(types.SET_DIFF_FILE_VIEWER, {
        filePath: diffFile.file_path,
        viewer: {
          ...diffFile.alternate_viewer,
          automaticallyCollapsed: false,
          manuallyCollapsed: false,
          forceOpen: false,
        },
      });
      commit(types.SET_CURRENT_VIEW_DIFF_FILE_LINES, { filePath: diffFile.file_path, lines });
    });
}

export const setFileCollapsedByUser = ({ commit }, { filePath, collapsed }) => {
  commit(types.SET_FILE_COLLAPSED, { filePath, collapsed, trigger: DIFF_FILE_MANUAL_COLLAPSE });
};

export const setFileCollapsedAutomatically = ({ commit }, { filePath, collapsed }) => {
  commit(types.SET_FILE_COLLAPSED, { filePath, collapsed, trigger: DIFF_FILE_AUTOMATIC_COLLAPSE });
};

export function setFileForcedOpen({ commit }, { filePath, forced }) {
  commit(types.SET_FILE_FORCED_OPEN, { filePath, forced });
}

export const setSuggestPopoverDismissed = ({ commit, state }) =>
  axios
    .post(state.dismissEndpoint, {
      feature_name: 'suggest_popover_dismissed',
    })
    .then(() => {
      commit(types.SET_SHOW_SUGGEST_POPOVER);
    })
    .catch(() => {
      createAlert({
        message: ERROR_DISMISSING_SUGESTION_POPOVER,
      });
    });

export function changeCurrentCommit({ dispatch, commit, state }, { commitId }) {
  if (!commitId) {
    return Promise.reject(new Error('`commitId` is a required argument'));
  }
  if (!state.commit) {
    return Promise.reject(new Error('`state` must already contain a valid `commit`')); // eslint-disable-line @gitlab/require-i18n-strings
  }

  // this is less than ideal, see: https://gitlab.com/gitlab-org/gitlab/-/issues/215421
  const commitRE = new RegExp(state.commit.id, 'g');

  commit(types.SET_DIFF_FILES, []);
  commit(types.SET_BASE_CONFIG, {
    ...state,
    endpoint: state.endpoint.replace(commitRE, commitId),
    endpointBatch: state.endpointBatch.replace(commitRE, commitId),
    endpointMetadata: state.endpointMetadata.replace(commitRE, commitId),
  });

  return dispatch('fetchDiffFilesMeta');
}

export function moveToNeighboringCommit({ dispatch, state }, { direction }) {
  const previousCommitId = state.commit?.prev_commit_id;
  const nextCommitId = state.commit?.next_commit_id;
  const canMove = {
    next: !state.isLoading && nextCommitId,
    previous: !state.isLoading && previousCommitId,
  };
  let commitId;

  if (direction === 'next' && canMove.next) {
    commitId = nextCommitId;
  } else if (direction === 'previous' && canMove.previous) {
    commitId = previousCommitId;
  }

  if (commitId) {
    dispatch('changeCurrentCommit', { commitId });
  }
}

export const rereadNoteHash = ({ state, dispatch }) => {
  const urlHash = window?.location?.hash;

  if (isUrlHashNoteLink(urlHash)) {
    dispatch('setCurrentDiffFileIdFromNote', urlHash.split('_').pop())
      .then(() => {
        if (state.viewDiffsFileByFile) {
          dispatch('fetchFileByFile');
        }
      })
      .catch(() => {
        createAlert({
          message: DISCUSSION_SINGLE_DIFF_FAILED,
        });
      });
  }
};

export const setCurrentDiffFileIdFromNote = ({ commit, getters, rootGetters }, noteId) => {
  const note = rootGetters.notesById[noteId];

  if (!note) return;

  const fileHash = rootGetters.getDiscussion(note.discussion_id).diff_file?.file_hash;

  if (fileHash && getters.flatBlobsList.some((f) => f.fileHash === fileHash)) {
    commit(types.SET_CURRENT_DIFF_FILE, fileHash);
  }
};

export const navigateToDiffFileIndex = ({ state, getters, commit, dispatch }, index) => {
  const { fileHash } = getters.flatBlobsList[index];
  document.location.hash = fileHash;

  commit(types.SET_CURRENT_DIFF_FILE, fileHash);

  if (state.viewDiffsFileByFile) {
    dispatch('fetchFileByFile');
  }
};

export const setFileByFile = ({ state, commit }, { fileByFile }) => {
  commit(types.SET_FILE_BY_FILE, fileByFile);

  const events = [TRACKING_CLICK_SINGLE_FILE_SETTING];

  if (fileByFile) {
    events.push(TRACKING_SINGLE_FILE_MODE);
  } else {
    events.push(TRACKING_MULTIPLE_FILES_MODE);
  }

  queueRedisHllEvents(events);

  return axios
    .put(state.endpointUpdateUser, {
      view_diffs_file_by_file: fileByFile,
    })
    .then(() => {
      // https://gitlab.com/gitlab-org/gitlab/-/issues/326961
      // We can't even do a simple console warning here because
      // the pipeline will fail. However, the issue above will
      // eventually handle errors appropriately.
      // console.warn('Saving the file-by-fil user preference failed.');
    });
};

export function reviewFile({ commit, state }, { file, reviewed = true }) {
  const { mrPath } = getDerivedMergeRequestInformation({ endpoint: file.load_collapsed_diff_url });
  const reviews = markFileReview(state.mrReviews, file, reviewed);

  setReviewsForMergeRequest(mrPath, reviews);

  commit(types.SET_DIFF_FILE_VIEWED, { id: file.file_hash, seen: reviewed });
  commit(types.SET_MR_FILE_REVIEWS, reviews);
}

export const disableVirtualScroller = ({ commit }) => commit(types.DISABLE_VIRTUAL_SCROLLING);

export const toggleFileCommentForm = ({ commit }, filePath) =>
  commit(types.TOGGLE_FILE_COMMENT_FORM, filePath);

export const addDraftToFile = ({ commit }, { filePath, draft }) =>
  commit(types.ADD_DRAFT_TO_FILE, { filePath, draft });

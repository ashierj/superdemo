import { s__, sprintf } from '~/locale';

export const i18n = {
  GENIE_TOOLTIP: s__('AI|What does the selected code mean?'),
  GENIE_NO_CONTAINER_ERROR: s__("AI|The container element wasn't found, stopping AI Genie."),
  GENIE_CHAT_TITLE: s__('AI|Code Explanation'),
  GENIE_CHAT_CLOSE_LABEL: s__('AI|Close the Code Explanation'),
  GENIE_CHAT_LEGAL_NOTICE: sprintf(
    s__(
      'AI|You are not allowed to copy any part of this output into issues, comments, GitLab source code, commit messages, merge requests or any other user interface in the %{gitlabOrg} or %{gitlabCom} groups.',
    ),
    { gitlabOrg: '<code>/gitlab-org</code>', gitlabCom: '<code>/gitlab-com</code>' },
    false,
  ),
  GENIE_CHAT_LEGAL_GENERATED_BY_AI: s__('AI|Responses generated by AI'),
  REQUEST_ERROR: s__('AI|Something went wrong. Please try again later'),
  EXPERIMENT_BADGE: s__('AI|Experiment'),
  EXPLAIN_CODE_PROMPT: s__(
    'AI|Explain the code from %{filePath} in human understandable language presented in Markdown format. In the response add neither original code snippet nor any title. `%{text}`',
  ),
  TOO_LONG_ERROR_MESSAGE: s__(
    'AI|There is too much text in the chat. Please try again with a shorter text.',
  ),
  GENIE_CHAT_PROMPT_PLACEHOLDER: s__('AI|You can ask AI for more information.'),
};
export const TOO_LONG_ERROR_TYPE = 'too-long';
export const AI_GENIE_DEBOUNCE = 300;
export const GENIE_CHAT_MODEL_ROLES = {
  user: 'user',
  system: 'system',
  assistant: 'assistant',
};

export const FEEDBACK_OPTIONS = [
  {
    title: s__('AI|Helpful'),
    icon: 'thumb-up',
    value: 'helpful',
  },
  {
    title: s__('AI|Unhelpful'),
    icon: 'thumb-down',
    value: 'unhelpful',
  },
  {
    title: s__('AI|Wrong'),
    icon: 'status_warning',
    value: 'wrong',
  },
];

const MODEL_MAX_TOKENS = 4096; // max for 'gpt-3.5-turbo' model as per https://platform.openai.com/docs/models/gpt-3-5
export const MAX_RESPONSE_TOKENS = 300;
export const TOKENS_THRESHOLD = MODEL_MAX_TOKENS * 0.85; // We account for 15% fault in tokens calculation

export const EXPLAIN_CODE_TRACKING_EVENT_NAME = 'explain_code_blob_viewer';

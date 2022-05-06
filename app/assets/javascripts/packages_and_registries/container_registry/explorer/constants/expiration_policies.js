import { s__ } from '~/locale';

export const EXPIRATION_POLICY_WILL_RUN_IN = s__(
  'ContainerRegistry|Expiration policy will run in %{time}',
);
export const EXPIRATION_POLICY_DISABLED_TEXT = s__(
  'ContainerRegistry|Expiration policy is disabled.',
);
export const DELETE_ALERT_TITLE = s__('ContainerRegistry|Some tags were not deleted');
export const DELETE_ALERT_LINK_TEXT = s__(
  'ContainerRegistry|The cleanup policy timed out before it could delete all tags. An administrator can %{adminLinkStart}manually run cleanup now%{adminLinkEnd} or you can wait for the cleanup policy to automatically run again. %{docLinkStart}More information%{docLinkEnd}',
);
export const PARTIAL_CLEANUP_CONTINUE_MESSAGE = s__(
  'ContainerRegistry|The cleanup will continue within %{time}. %{linkStart}Learn more%{linkEnd}',
);
export const SET_UP_CLEANUP = s__('ContainerRegistry|Set up cleanup');

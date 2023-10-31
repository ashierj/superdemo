import eventHub from '~/invite_members/event_hub';
import { ULTIMATE_TRIAL_BENEFIT_MODAL } from 'ee/pages/projects/learn_gitlab/constants';
import { inviteMembersTrackingOptions as ceInviteMembersTrackingOptions } from '~/invite_members/utils/member_utils';
import { addExperimentContext } from '~/tracking/utils';
import { LEARN_GITLAB } from '../constants';

export { memberName } from '~/invite_members/utils/member_utils';

function isOnLearnGitlab(source) {
  return source === LEARN_GITLAB;
}

export function triggerExternalAlert(source) {
  if (isOnLearnGitlab(source)) {
    eventHub.$emit('showSuccessfulInvitationsAlert');
    return true;
  }

  return false;
}

export function inviteMembersTrackingOptions(options) {
  const baseOptions = ceInviteMembersTrackingOptions(options);

  if (options.celebrate) {
    return addExperimentContext({ experiment: ULTIMATE_TRIAL_BENEFIT_MODAL, ...baseOptions });
  }

  return baseOptions;
}

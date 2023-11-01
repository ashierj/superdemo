import {
  triggerExternalAlert,
  inviteMembersTrackingOptions,
} from 'ee/invite_members/utils/member_utils';
import { LEARN_GITLAB } from 'ee/invite_members/constants';
import { ULTIMATE_TRIAL_BENEFIT_MODAL } from 'ee/pages/projects/learn_gitlab/constants';
import { TRACKING_CONTEXT_SCHEMA } from '~/experimentation/constants';
import eventHub from '~/invite_members/event_hub';

jest.mock('~/lib/utils/url_utility');

describe('Trigger External Alert', () => {
  it.each([
    [LEARN_GITLAB, true],
    ['blah', false],
  ])(`returns result if it should trigger external alert: %j`, (source, result) => {
    jest.spyOn(eventHub, '$emit').mockImplementation();

    expect(triggerExternalAlert(source)).toBe(result);

    if (result) {
      expect(eventHub.$emit).toHaveBeenCalledWith('showSuccessfulInvitationsAlert');
    } else {
      expect(eventHub.$emit).not.toHaveBeenCalled();
    }
  });
});

describe('inviteMembersTrackingOptions', () => {
  it('returns with the label when celebrate is null', () => {
    expect(inviteMembersTrackingOptions({ label: '_label_', celebrate: null })).toStrictEqual({
      label: '_label_',
    });
  });

  it('returns with the label when celebrate is false', () => {
    expect(inviteMembersTrackingOptions({ label: '_label_', celebrate: false })).toStrictEqual({
      label: '_label_',
    });
  });

  it('returns with the label when celebrate is not passed', () => {
    expect(inviteMembersTrackingOptions({ label: '_label_' })).toStrictEqual({ label: '_label_' });
  });

  it('adds the experiment context when experiment is found in the window for celebrate', () => {
    window.gl = window.gl || {};
    window.gl.experiments = {
      [`${ULTIMATE_TRIAL_BENEFIT_MODAL}`]: {},
    };

    expect(inviteMembersTrackingOptions({ label: '_label_', celebrate: true })).toStrictEqual({
      label: '_label_',
      context: { data: {}, schema: TRACKING_CONTEXT_SCHEMA },
    });
  });

  it('does not add the experiment context when experiment is not found in the window for celebrate', () => {
    window.gl = window.gl || {};
    window.gl.experiments = {};

    expect(inviteMembersTrackingOptions({ label: '_label_', celebrate: true })).toStrictEqual({
      label: '_label_',
    });
  });
});

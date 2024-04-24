import '~/pages/projects';
import { initTrialStatusWidgetAndPopover } from 'ee/contextual_sidebar/init_trial_status_widget_and_popover';
import { shouldHandRaiseLeadMount } from 'ee/hand_raise_leads/hand_raise_lead';

initTrialStatusWidgetAndPopover();
shouldHandRaiseLeadMount();

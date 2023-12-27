import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import { thWidthPercent } from '~/lib/utils/table_utility';

export const ADD_ON_CODE_SUGGESTIONS = 'CODE_SUGGESTIONS';
export const codeSuggestionsLearnMoreLink = `${PROMO_URL}/solutions/code-suggestions/`;
export const salesLink = `${PROMO_URL}/sales/`;

export const addOnEligibleUserListTableFields = {
  codeSuggestionsAddon: {
    key: 'codeSuggestionsAddon',
    label: s__('CodeSuggestions|Code Suggestions add-on'),
    thClass: thWidthPercent(25),
    tdClass: 'gl-vertical-align-middle!',
  },
  email: {
    key: 'email',
    label: __('Email'),
    thClass: thWidthPercent(15),
    tdClass: 'gl-vertical-align-middle!',
  },
  emailWide: {
    key: 'email',
    label: __('Email'),
    thClass: thWidthPercent(20),
    tdClass: 'gl-vertical-align-middle!',
  },
  lastActivityTime: {
    key: 'lastActivityTime',
    label: __('Last GitLab activity'),
    thClass: thWidthPercent(15),
    tdClass: 'gl-vertical-align-middle!',
  },
  lastActivityTimeWide: {
    key: 'lastActivityTime',
    label: __('Last GitLab activity'),
    thClass: thWidthPercent(25),
    tdClass: 'gl-vertical-align-middle!',
  },
  maxRole: {
    key: 'maxRole',
    label: __('Max role'),
    thClass: thWidthPercent(15),
    tdClass: 'gl-vertical-align-middle!',
  },
  user: {
    key: 'user',
    label: __('User'),
    thClass: `gl-pl-2! ${thWidthPercent(30)}`,
    tdClass: 'gl-vertical-align-middle! gl-pl-2!',
  },
};

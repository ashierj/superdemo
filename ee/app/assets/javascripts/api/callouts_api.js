import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';

const USERS_CALLOUTS_PATH = '/-/users/callouts';

export const dismissUsersCallouts = (featureName) => {
  return axios.post(buildApiUrl(USERS_CALLOUTS_PATH), { feature_name: featureName });
};

import MockAdapter from 'axios-mock-adapter';
import * as CalloutsApi from 'ee/api/callouts_api';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('CalloutsApi', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('dismissUsersCallouts', () => {
    const expectedUrl = '/-/users/callouts';
    const featureName = '_feature_name_';

    it('sends featureName parameter', async () => {
      jest.spyOn(axios, 'post');
      mock.onPost(expectedUrl).replyOnce(HTTP_STATUS_OK, []);

      const { data } = await CalloutsApi.dismissUsersCallouts(featureName);

      expect(data).toEqual([]);
      expect(axios.post).toHaveBeenCalledWith(expectedUrl, { feature_name: featureName });
    });
  });
});

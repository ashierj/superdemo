import createState from 'ee/members/promotion_requests/store/state';
import { data, pagination } from '../mock_data';

describe('Promotion requests store state', () => {
  it('inits the state', () => {
    const state = createState({ data, pagination });
    expect(state).toEqual({ data, pagination });
  });
});

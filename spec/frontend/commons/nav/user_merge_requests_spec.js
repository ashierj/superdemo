import { refreshUserMergeRequestCounts } from '~/commons/nav/user_merge_requests';

describe('User Merge Requests', () => {
  beforeEach(() => {
    jest.spyOn(document, 'dispatchEvent').mockReturnValue(false);
    global.gon.use_new_navigation = true;
  });

  describe('refreshUserMergeRequestCounts', () => {
    it('emits event to refetch counts', async () => {
      await refreshUserMergeRequestCounts();
      expect(document.dispatchEvent).toHaveBeenCalledWith(new CustomEvent('todo:toggle'));
    });
  });
});

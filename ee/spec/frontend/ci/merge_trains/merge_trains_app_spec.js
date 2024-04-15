import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MergeTrainsApp from 'ee/ci/merge_trains/merge_trains_app.vue';

describe('MergeTrainsApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(MergeTrainsApp, { provide: { fullPath: 'namespace/project' } });
  };

  it('renders the merge trains app', () => {
    createComponent();

    expect(wrapper.findComponent(MergeTrainsApp).exists()).toBe(true);
  });
});

import { GlFilteredSearchToken } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TracingBaseSearchToken from 'ee/tracing/list/filter_bar/tracing_base_search_token.vue';

describe('AttributeSearchToken', () => {
  let wrapper;

  const findBaseToken = () => wrapper.findComponent(GlFilteredSearchToken);

  const defaultProps = {
    active: true,
    config: {
      title: 'test-title',
    },
    value: { data: '' },
    currentValue: [],
  };

  const mount = (propsData = defaultProps) => {
    wrapper = shallowMountExtended(TracingBaseSearchToken, {
      propsData,
    });
  };
  beforeEach(() => {
    mount();
  });

  it('renders a BaseToken', () => {
    const base = findBaseToken();
    expect(base.exists()).toBe(true);
    expect(base.props('active')).toEqual(wrapper.props('active'));
    expect(base.props('value')).toEqual(wrapper.props('value'));
    expect(base.props('config')).toEqual(wrapper.props('config'));
    expect(findBaseToken().props('viewOnly')).toBe(true);
  });

  it('sets the token to view-only if the operation service token are not set', () => {
    mount({ ...defaultProps, currentValue: [{ type: 'operation' }] });
    expect(findBaseToken().props('viewOnly')).toBe(true);
  });

  it('sets the token to view-only if the service service token are not set', () => {
    mount({ ...defaultProps, currentValue: [{ type: 'service' }] });
    expect(findBaseToken().props('viewOnly')).toBe(true);
  });

  it('does not set the token to view-only if the service service and operation tokens are set', () => {
    mount({ ...defaultProps, currentValue: [{ type: 'service' }, { type: 'operation' }] });
    expect(findBaseToken().props('viewOnly')).toBe(true);
  });
});

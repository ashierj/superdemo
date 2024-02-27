import { GlEmptyState } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import CustomRolesEmptyState from 'ee/roles_and_permissions/components/custom_roles_empty_state.vue';

describe('CustomRolesEmptyState', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mount(CustomRolesEmptyState, {
      provide: {
        documentationPath: 'http://foo.bar',
        emptyStateSvgPath: 'empty.svg',
      },
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  beforeEach(() => {
    createComponent();
  });

  it('renders the empty state', () => {
    expect(findEmptyState().exists()).toBe(true);

    expect(findEmptyState().props()).toMatchObject({
      title: 'Create custom roles',
      svgPath: 'empty.svg',
      primaryButtonLink: '#',
      primaryButtonText: 'Create new role',
    });

    expect(findEmptyState().text()).toContain(
      'Create a custom role with specific abilities by starting with a base role and adding custom permissions.',
    );
    expect(findEmptyState().text()).toContain('Learn more about custom roles.');
  });
});

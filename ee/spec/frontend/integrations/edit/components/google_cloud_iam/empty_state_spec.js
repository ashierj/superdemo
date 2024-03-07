import { GlButton, GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import EmptyAdminAppsSvg from '@gitlab/svgs/dist/illustrations/empty-state/empty-admin-apps-md.svg';
import { shallowMount } from '@vue/test-utils';
import {
  STATE_GUIDED,
  STATE_MANUAL,
} from 'ee/integrations/edit/components/google_cloud_iam/constants';
import EmptyState from 'ee/integrations/edit/components/google_cloud_iam/empty_state.vue';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';

describe('EmptyState', () => {
  let wrapper;
  const createComponent = () => {
    wrapper = shallowMount(EmptyState, {
      stubs: {
        GlEmptyState,
        GlSprintf,
      },
    });
  };

  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findDescription = () => wrapper.find('p');
  const findLink = () => wrapper.findComponent(GlLink);
  const findInviteMembersTrigger = () => wrapper.findComponent(InviteMembersTrigger);
  const findButton = (variant) =>
    wrapper.findAllComponents(GlButton).filter((button) => button.props('variant') === variant);

  beforeEach(() => {
    createComponent();
  });

  it('renders GlEmptyState', () => {
    expect(findGlEmptyState().props()).toMatchObject({
      svgPath: EmptyAdminAppsSvg,
      title: 'Connect to Google Cloud',
    });
  });

  it('renders description', () => {
    expect(findDescription().text()).toContain(
      'Connect to Google Cloud with workload identity federation. Select Guided setup if you can manage workload identity federation in Google Cloud.',
    );
  });

  it('renders link to Google Cloud documentation', () => {
    const link = findLink();
    expect(link.attributes()).toMatchObject({
      href:
        'https://cloud.google.com/iam/docs/manage-workload-identity-pools-providers#required-roles',
      rel: 'noopener noreferrer',
      target: '_blank',
    });
    expect(link.text()).toBe('What are the required permissions?');
  });

  describe('Guided setup button', () => {
    let guidedButton;

    beforeEach(() => {
      guidedButton = findButton('confirm').at(0);
    });

    it('renders variant confirm button', () => {
      expect(guidedButton.text()).toBe('Guided setup');
    });

    it('emits `show` event', () => {
      expect(wrapper.emitted().show).toBeUndefined();

      guidedButton.vm.$emit('click');

      expect(wrapper.emitted().show).toHaveLength(1);
      expect(wrapper.emitted().show[0]).toContain(STATE_GUIDED);
    });
  });

  describe('Manual setup button', () => {
    let manualButton;

    beforeEach(() => {
      manualButton = findButton('default').at(0);
    });

    it('renders variant default button', () => {
      expect(manualButton.text()).toBe('Manual setup');
    });

    it('emits `show` event', () => {
      expect(wrapper.emitted().show).toBeUndefined();

      manualButton.vm.$emit('click');

      expect(wrapper.emitted().show).toHaveLength(1);
      expect(wrapper.emitted().show[0]).toContain(STATE_MANUAL);
    });
  });

  it('renders an InviteMembersTrigger component', () => {
    expect(findInviteMembersTrigger().exists()).toBe(true);
  });
});

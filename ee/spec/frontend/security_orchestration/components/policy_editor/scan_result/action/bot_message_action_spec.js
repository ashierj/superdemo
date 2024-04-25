import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SectionLayout from 'ee/security_orchestration/components/policy_editor/section_layout.vue';
import BotCommentAction from 'ee/security_orchestration/components/policy_editor/scan_result/action/bot_message_action.vue';

describe('BotCommentAction', () => {
  let wrapper;

  const factory = () => {
    wrapper = shallowMount(BotCommentAction, { stubs: { GlSprintf } });
  };

  const findSectionLayout = () => wrapper.findComponent(SectionLayout);

  it('renders the correct text', () => {
    factory();
    expect(findSectionLayout().exists()).toBe(true);
    expect(findSectionLayout().text()).toBe(
      'Send a bot message as comment to merge request creator.',
    );
  });
});

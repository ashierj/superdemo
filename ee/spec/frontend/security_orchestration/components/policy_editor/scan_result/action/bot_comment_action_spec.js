import { shallowMount } from '@vue/test-utils';
import SectionLayout from 'ee/security_orchestration/components/policy_editor/section_layout.vue';
import BotCommentAction from 'ee/security_orchestration/components/policy_editor/scan_result/action/bot_comment_action.vue';

describe('BotCommentAction', () => {
  let wrapper;

  const factory = () => {
    wrapper = shallowMount(BotCommentAction);
  };

  const findSectionLayout = () => wrapper.findComponent(SectionLayout);

  it('renders', () => {
    factory();
    expect(findSectionLayout().exists()).toBe(true);
  });
});

import { shallowMount } from '@vue/test-utils';
import ActionSection from 'ee/security_orchestration/components/policy_editor/scan_result/action/action_section_new.vue';
import ApproverAction from 'ee/security_orchestration/components/policy_editor/scan_result/action/approver_action.vue';
import BotCommentAction from 'ee/security_orchestration/components/policy_editor/scan_result/action/bot_comment_action.vue';
import {
  BOT_COMMENT_TYPE,
  REQUIRE_APPROVAL_TYPE,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib';

describe('ActionSection', () => {
  let wrapper;

  const defaultProps = {
    initAction: { type: REQUIRE_APPROVAL_TYPE },
    existingApprovers: {},
  };
  const factory = ({ props = {} } = {}) => {
    wrapper = shallowMount(ActionSection, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findApproverAction = () => wrapper.findComponent(ApproverAction);
  const findBotCommentAction = () => wrapper.findComponent(BotCommentAction);

  describe('Approval Action', () => {
    beforeEach(() => {
      factory();
    });

    it('renders an approver action for that type of action', () => {
      expect(findApproverAction().exists()).toBe(true);
      expect(findBotCommentAction().exists()).toBe(false);
    });

    describe('events', () => {
      it('passes through the "error" event', () => {
        findApproverAction().vm.$emit('error');
        expect(wrapper.emitted('error')).toEqual([[]]);
      });

      it('passes through the "update-approvers" event', () => {
        const event = 'event';
        findApproverAction().vm.$emit('updateApprovers', event);
        expect(wrapper.emitted('updateApprovers')).toEqual([[event]]);
      });

      it('passes through the "changed" event', () => {
        const event = 'event';
        findApproverAction().vm.$emit('changed', event);
        expect(wrapper.emitted('changed')).toEqual([[event]]);
      });

      it('passes through the "remove" event', () => {
        findApproverAction().vm.$emit('remove');
        expect(wrapper.emitted('remove')).toEqual([[]]);
      });
    });
  });

  describe('Bot Comment Action', () => {
    it('renders a bot comment action for that type of action', () => {
      factory({ props: { initAction: { type: BOT_COMMENT_TYPE } } });
      expect(findBotCommentAction().exists()).toBe(true);
      expect(findApproverAction().exists()).toBe(false);
    });
  });
});

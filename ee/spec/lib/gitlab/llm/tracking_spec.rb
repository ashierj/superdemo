# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Tracking, feature_category: :ai_abstraction_layer do
  let(:user) { build(:user) }
  let(:resource) { build(:project) }
  let(:ai_action_name) { 'chat' }
  let(:user_agent) { nil }
  let(:request_id) { 'uuid' }

  let(:ai_message) do
    build(:ai_message,
      user: user, resource: resource, ai_action: ai_action_name, request_id: request_id, user_agent: user_agent
    )
  end

  describe '.event_for_ai_message' do
    subject(:event_for_ai_message) do
      described_class.event_for_ai_message('Category', 'my_action', ai_message: ai_message)
    end

    it 'tracks event with correct params' do
      event_for_ai_message

      expect_snowplow_event(
        category: 'Category',
        action: 'my_action',
        label: ai_action_name,
        property: request_id,
        user: user,
        client: nil
      )
    end

    context 'with browser user agent' do
      let(:user_agent) { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)' }

      it 'tracks event with correct params' do
        event_for_ai_message

        expect_snowplow_event(
          category: 'Category',
          action: 'my_action',
          label: ai_action_name,
          property: request_id,
          user: user,
          client: 'web'
        )
      end
    end

    context 'with vscode user agent' do
      let(:user_agent) { 'vs-code-gitlab-workflow/3.11.1 VSCode/1.52.1 Node.js/12.14.1 (darwin; x64)' }

      it 'tracks event with correct params' do
        event_for_ai_message

        expect_snowplow_event(
          category: 'Category',
          action: 'my_action',
          label: ai_action_name,
          property: request_id,
          user: user,
          client: 'vscode'
        )
      end
    end
  end
end

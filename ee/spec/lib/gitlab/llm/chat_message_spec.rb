# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::ChatMessage, feature_category: :duo_chat do
  subject { build(:ai_chat_message) }

  describe '#conversation_reset?' do
    it 'returns true for reset message' do
      expect(build(:ai_chat_message, content: '/reset')).to be_conversation_reset
    end

    it 'returns false for regular message' do
      expect(subject).not_to be_conversation_reset
    end
  end

  describe '#save!', :clean_gitlab_redis_cache do
    let(:storage) { Gitlab::Llm::ChatStorage.new(subject.user) }

    it 'saves the message to chat storage' do
      expect(storage.messages).to be_empty

      subject.save!

      reloaded_message = storage.messages.last

      expect(reloaded_message.id).to eq(subject.id)
      expect(reloaded_message.request_id).to eq(subject.request_id)
      expect(reloaded_message.content).to eq(subject.content)
      expect(reloaded_message.extras).to eq(subject.extras)
      expect(reloaded_message.errors).to eq(subject.errors)
      expect(reloaded_message.role).to eq(subject.role)
      expect(reloaded_message.timestamp).to be_within(1).of(subject.timestamp)
    end
  end
end

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

  describe '#clean_history?' do
    it 'returns true for /clean message' do
      expect(build(:ai_chat_message, content: '/clean')).to be_clean_history
    end

    it 'returns false for regular message' do
      expect(subject).not_to be_clean_history
    end
  end

  describe '#question?' do
    where(:role, :content, :expectation) do
      [
        ['user', 'foo?', true],
        ['user', '/reset', false],
        ['user', '/clean', false],
        ['assistant', 'foo?', false]
      ]
    end

    with_them do
      it "returns expectation" do
        subject.assign_attributes(role: role, content: content)

        expect(subject.question?).to eq(expectation)
      end
    end
  end

  describe '#save!' do
    it 'saves the message to chat storage' do
      expect_next_instance_of(Gitlab::Llm::ChatStorage, subject.user) do |instance|
        expect(instance).to receive(:add).with(subject)
      end

      subject.save!
    end

    context 'for /reset message' do
      it 'saves the message to chat storage' do
        message = build(:ai_chat_message, content: '/reset')

        expect_next_instance_of(Gitlab::Llm::ChatStorage, message.user) do |instance|
          expect(instance).to receive(:add).with(message)
        end

        message.save!
      end
    end

    context 'for /clean message' do
      it 'removes all messages from chat storage' do
        message = build(:ai_chat_message, content: '/clean')

        expect_next_instance_of(Gitlab::Llm::ChatStorage, message.user) do |instance|
          expect(instance).to receive(:clean!)
        end

        message.save!
      end
    end
  end
end

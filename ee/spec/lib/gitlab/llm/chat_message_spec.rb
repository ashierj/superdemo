# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::ChatMessage, feature_category: :duo_chat do
  subject { build(:ai_chat_message, agent_version_id: 1) }

  describe '#conversation_reset?' do
    it 'returns true for reset message' do
      expect(build(:ai_chat_message, content: '/reset')).to be_conversation_reset
    end

    it 'returns false for regular message' do
      expect(subject).not_to be_conversation_reset
    end
  end

  describe '#clean_history?' do
    Gitlab::Llm::ChatMessage::CLEAN_HISTORY_MESSAGES.each do |clean_message|
      it "returns true for '#{clean_message}'" do
        expect(build(:ai_chat_message, content: clean_message)).to be_clean_history
      end
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
      expect_next_instance_of(Gitlab::Llm::ChatStorage, subject.user, subject.agent_version_id) do |instance|
        expect(instance).to receive(:add).with(subject)
      end

      subject.save!
    end

    context 'for /reset message' do
      it 'saves the message to chat storage' do
        message = build(:ai_chat_message, content: '/reset', agent_version_id: 1)

        expect_next_instance_of(Gitlab::Llm::ChatStorage, message.user, message.agent_version_id) do |instance|
          expect(instance).to receive(:add).with(message)
        end

        message.save!
      end
    end

    context 'for slash commands to clean history' do
      Gitlab::Llm::ChatMessage::CLEAN_HISTORY_MESSAGES.each do |clean_message|
        it "removes all messages from chat storage for message '#{clean_message}'" do
          message = build(:ai_chat_message, content: clean_message, agent_version_id: 1)

          expect_next_instance_of(Gitlab::Llm::ChatStorage, message.user, message.agent_version_id) do |instance|
            expect(instance).to receive(:clean!)
          end

          message.save!
        end
      end
    end
  end

  describe "#chat?" do
    it 'returns true for chat message' do
      expect(subject).to be_chat
    end
  end
end

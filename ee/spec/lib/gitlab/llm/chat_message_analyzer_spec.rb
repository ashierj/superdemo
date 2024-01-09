# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::ChatMessageAnalyzer, feature_category: :duo_chat do
  let(:messages) { [build(:ai_chat_message, content: 'What is the pipeline?')] }

  subject(:result) { described_class.new(messages).execute }

  describe '#execute', :freeze_time do
    it 'succeeds' do
      expect(result).to match(
        'number_of_conversations' => 1,
        'number_of_questions_in_conversation' => 1,
        'length_of_questions_in_conversation' => 21,
        'length_of_questions' => 21,
        'first_question_after_reset' => false,
        'time_since_beginning_of_conversation' => 0
      )
    end

    context 'with reset' do
      let(:messages) do
        [
          build(:ai_chat_message, content: 'what?', timestamp: 1.second.ago),
          build(:ai_chat_message, :assistant, content: 'abc'),
          build(:ai_chat_message, content: '/reset'),
          build(:ai_chat_message, content: 'why?')
        ]
      end

      it 'handles reset' do
        expect(result).to match(
          'number_of_conversations' => 2,
          'number_of_questions_in_conversation' => 1,
          'length_of_questions_in_conversation' => 4,
          'length_of_questions' => 4,
          'first_question_after_reset' => true,
          'time_since_beginning_of_conversation' => 0,
          'time_since_last_question' => 1
        )
      end
    end

    context 'with previous question' do
      let(:messages) do
        [
          build(:ai_chat_message, content: 'what?', timestamp: 1.second.ago),
          build(:ai_chat_message, :assistant, content: 'abc'),
          build(:ai_chat_message, content: 'why?')
        ]
      end

      it 'handles multiple questions in conversation' do
        expect(result).to match(
          'number_of_conversations' => 1,
          'number_of_questions_in_conversation' => 2,
          'length_of_questions_in_conversation' => 9,
          'length_of_questions' => 4,
          'first_question_after_reset' => false,
          'time_since_beginning_of_conversation' => 1,
          'time_since_last_question' => 1
        )
      end
    end

    context 'when messages is empty' do
      let(:messages) { [] }

      it { is_expected.to eq({}) }
    end
  end
end

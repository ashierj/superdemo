# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::SlashCommand, feature_category: :duo_chat do
  let(:content) { '/explain' }
  let(:tools) { Gitlab::Llm::Completions::Chat::COMMAND_TOOLS }
  let(:message) do
    build(:ai_chat_message, user: instance_double(User), resource: nil, request_id: 'uuid', content: content)
  end

  describe '.for' do
    subject { described_class.for(message: message, tools: tools) }

    it { is_expected.to be_an_instance_of(described_class) }

    context 'when command is unknown' do
      let(:content) { '/something' }

      it { is_expected.to be_nil }
    end

    context 'when tools are empty' do
      let(:tools) { [] }

      it { is_expected.to be_nil }
    end
  end

  describe '#prompt_options' do
    let(:user_input) { nil }
    let(:instruction_with_input) { 'explain %<input>s in the code' }
    let(:params) do
      {
        name: content,
        user_input: user_input,
        tool: nil,
        command_options: {
          instruction: 'explain the code',
          instruction_with_input: instruction_with_input
        }
      }
    end

    subject { described_class.new(**params).prompt_options }

    it { is_expected.to eq({ input: 'explain the code' }) }

    context 'when user input is present' do
      let(:user_input) { 'method params' }

      it { is_expected.to eq({ input: 'explain method params in the code' }) }

      context 'when instruction_with_input is not part of command definition' do
        let(:instruction_with_input) { nil }

        it { is_expected.to eq({ input: 'explain the code' }) }
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Requests::AiGateway, feature_category: :duo_chat do
  let_it_be(:user) { build(:user) }

  describe 'initializer' do
    it 'initializes the AI Gateway client' do
      request = described_class.new(user)

      expect(request.ai_client.class).to eq(::Gitlab::Llm::AiGateway::Client)
    end
  end

  describe '#request' do
    subject(:request) { instance.request(params) }

    let(:instance) { described_class.new(user) }
    let(:logger) { instance_double(Gitlab::Llm::Logger) }
    let(:ai_client) { double }
    let(:response) { 'Hello World' }
    let(:expected_params) do
      {
        prompt: "some user request"
      }
    end

    before do
      allow(Gitlab::Llm::Logger).to receive(:build).and_return(logger)
      allow(instance).to receive(:ai_client).and_return(ai_client)
    end

    context 'with prompt' do
      let(:params) { { prompt: "some user request" } }

      it 'calls the AI Gateway streaming endpoint and yields response without stripping it' do
        expect(ai_client).to receive(:stream).with(expected_params).and_yield(response)

        expect { |b| instance.request(params, &b) }.to yield_with_args(
          "Hello World"
        )
      end

      it 'returns the response from AI Gateway' do
        expect(ai_client).to receive(:stream).with(expected_params).and_return(response)

        expect(request).to eq("Hello World")
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Logger, feature_category: :ai_abstraction_layer do
  describe "log_level" do
    subject(:log_level) { described_class.build.level }

    context 'when LLM_DEBUG is not set' do
      it { is_expected.to eq ::Logger::INFO }
    end

    context 'when LLM_DEBUG=true' do
      before do
        stub_env('LLM_DEBUG', true)
      end

      it { is_expected.to eq ::Logger::DEBUG }
    end

    context 'when LLM_DEBUG=false' do
      before do
        stub_env('LLM_DEBUG', false)
      end

      it { is_expected.to eq ::Logger::INFO }
    end
  end

  describe "#info_or_debug" do
    let_it_be(:user) { create(:user) }
    let(:logger) { described_class.build }

    context 'with expanded_ai_logging switched on' do
      it 'logs on info level' do
        expect(logger).to receive(:info).with({ message: 'test' })

        logger.info_or_debug(user, message: 'test')
      end
    end

    context 'with expanded_ai_logging switched off' do
      before do
        stub_feature_flags(expanded_ai_logging: false)
      end

      it 'logs on debug level' do
        expect(logger).to receive(:debug).with({ message: 'test' })

        logger.info_or_debug(user, message: 'test')
      end
    end
  end
end

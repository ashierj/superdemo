# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../lib/code_suggestions/programming_language'

RSpec.describe CodeSuggestions::AiModels, feature_category: :code_suggestions do
  shared_examples 'selecting model family' do
    context 'when splitting by language' do
      context 'when language belongs to Anthropic' do
        let(:language) { instance_double(CodeSuggestions::ProgrammingLanguage, name: 'Ruby') }

        it { is_expected.to eq(described_class::ANTHROPIC) }
      end

      context 'when language does not belong to Anthropic' do
        let(:language) { instance_double(CodeSuggestions::ProgrammingLanguage, name: 'Python') }

        it { is_expected.to eq(described_class::VERTEX_AI) }
      end
    end

    context 'when not splitting by language' do
      let(:split_by_language) { false }

      it { is_expected.to eq(default) }
    end
  end

  describe '.code_completion_model_family' do
    let(:default) { described_class::VERTEX_AI }
    let(:split_by_language) { true }
    let(:language) { instance_double(CodeSuggestions::ProgrammingLanguage, name: 'Ruby') }

    subject(:code_completion_model_family) do
      described_class.code_completion_model_family(
        default: default,
        split_by_language: split_by_language,
        language: language
      )
    end

    it_behaves_like 'selecting model family'
  end

  describe '.code_generation_model_family' do
    let(:default) { described_class::VERTEX_AI }
    let(:split_by_language) { true }
    let(:language) { instance_double(CodeSuggestions::ProgrammingLanguage, name: 'Ruby') }

    subject(:code_generation_model_family) do
      described_class.code_generation_model_family(
        default: default,
        split_by_language: split_by_language,
        language: language
      )
    end

    it_behaves_like 'selecting model family'
  end
end

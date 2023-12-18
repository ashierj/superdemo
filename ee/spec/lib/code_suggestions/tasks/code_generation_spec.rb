# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::Tasks::CodeGeneration, feature_category: :code_suggestions do
  let(:prefix) { 'some prefix' }
  let(:suffix) { 'some suffix' }
  let(:instruction) { 'Add code for validating function' }
  let(:model_family) { CodeSuggestions::TaskFactory::VERTEX_AI }

  let(:current_file) do
    {
      'file_name' => 'test.py',
      'content_above_cursor' => prefix,
      'content_below_cursor' => suffix
    }.with_indifferent_access
  end

  let(:unsafe_params) do
    {
      'current_file' => current_file,
      'telemetry' => [{ 'model_engine' => 'vertex-ai' }]
    }.with_indifferent_access
  end

  let(:params) do
    {
      code_generation_model_family: model_family,
      prefix: prefix,
      instruction: instruction,
      current_file: current_file
    }
  end

  let(:expected_current_file) do
    { current_file: { file_name: 'test.py', content_above_cursor: 'fix', content_below_cursor: 'som' } }
  end

  let(:vertex_ai_request_params) { { prompt_version: 1, prompt: 'Vertex AI prompt' } }

  let(:vertex_ai_prompt) do
    instance_double(CodeSuggestions::Prompts::CodeGeneration::VertexAi, request_params: vertex_ai_request_params)
  end

  let(:anthropic_request_params) { { prompt_version: 2, prompt: 'Anthropic prompt' } }

  let(:anthropic_prompt) do
    instance_double(CodeSuggestions::Prompts::CodeGeneration::Anthropic, request_params: anthropic_request_params)
  end

  subject(:task) { described_class.new(params: params, unsafe_passthrough_params: unsafe_params) }

  describe '#body' do
    before do
      allow(CodeSuggestions::Prompts::CodeGeneration::VertexAi).to receive(:new).and_return(vertex_ai_prompt)
      allow(CodeSuggestions::Prompts::CodeGeneration::Anthropic).to receive(:new).and_return(anthropic_prompt)
      stub_const('CodeSuggestions::Tasks::Base::AI_GATEWAY_CONTENT_SIZE', 3)
    end

    context 'with vertex_ai model family' do
      it_behaves_like 'code suggestion task' do
        let(:endpoint_path) { 'v2/code/generations' }
        let(:body) { unsafe_params.merge(vertex_ai_request_params).merge(expected_current_file) }
      end

      it 'calls code creation Vertex AI' do
        task.body

        expect(CodeSuggestions::Prompts::CodeGeneration::VertexAi).to have_received(:new).with(params)
        expect(CodeSuggestions::Prompts::CodeGeneration::Anthropic).not_to have_received(:new)
      end
    end

    context 'with anthropic model family' do
      let(:model_family) { CodeSuggestions::TaskFactory::ANTHROPIC }

      it_behaves_like 'code suggestion task' do
        let(:endpoint_path) { 'v2/code/generations' }
        let(:body) { unsafe_params.merge(anthropic_request_params.merge(expected_current_file)) }
      end

      it 'calls code creation Anthropic' do
        task.body

        expect(CodeSuggestions::Prompts::CodeGeneration::VertexAi).not_to have_received(:new)
        expect(CodeSuggestions::Prompts::CodeGeneration::Anthropic).to have_received(:new).with(params)
      end
    end
  end
end

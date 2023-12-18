# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::Tasks::CodeCompletion, feature_category: :code_suggestions do
  let(:endpoint_path) { 'v2/code/completions' }

  let(:current_file) do
    {
      'file_name' => 'test.py',
      'content_above_cursor' => 'some prefix',
      'content_below_cursor' => 'some suffix'
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
      current_file: current_file,
      code_completion_model_family: model_family
    }
  end

  let(:expected_current_file) do
    { current_file: { file_name: 'test.py', content_above_cursor: 'fix', content_below_cursor: 'som' } }
  end

  let(:task) { described_class.new(params: params, unsafe_passthrough_params: unsafe_params) }

  before do
    stub_const('CodeSuggestions::Tasks::Base::AI_GATEWAY_CONTENT_SIZE', 3)
  end

  context 'when using Vertex' do
    let(:model_family) { CodeSuggestions::TaskFactory::VERTEX_AI }
    let(:request_params) { { prompt_version: 10 } }

    before do
      allow_next_instance_of(CodeSuggestions::Prompts::CodeCompletion::VertexAi) do |prompt|
        allow(prompt).to receive(:request_params).and_return(request_params)
      end
    end

    it_behaves_like 'code suggestion task' do
      let(:body) { unsafe_params.merge(request_params).merge(expected_current_file) }
    end
  end

  context 'when using Anthropic' do
    let(:model_family) { CodeSuggestions::TaskFactory::ANTHROPIC }
    let(:request_params) { { prompt_version: 10, prompt: 'foo' } }

    before do
      allow_next_instance_of(CodeSuggestions::Prompts::CodeCompletion::Anthropic) do |prompt|
        allow(prompt).to receive(:request_params).and_return(request_params)
      end
    end

    it_behaves_like 'code suggestion task' do
      let(:body) { unsafe_params.merge(request_params).merge(expected_current_file) }
    end
  end
end

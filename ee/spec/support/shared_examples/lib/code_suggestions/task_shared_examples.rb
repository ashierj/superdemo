# frozen_string_literal: true

RSpec.shared_examples 'code suggestion task' do
  let(:base_url) { 'https://cloud.gitlab.com/ai' }
  let(:endpoint) { "#{base_url}/#{endpoint_path}" }

  shared_examples_for 'valid endpoint' do
    it 'returns valid endpoint' do
      expect(task.endpoint).to eq endpoint
    end

    it 'returns body' do
      expect(Gitlab::Json.parse(task.body)).to eq body
    end
  end

  include_examples 'valid endpoint'

  context 'when use_cloud_connector_lb is disabled' do
    let(:base_url) { 'https://codesuggestions.gitlab.com' }

    before do
      stub_feature_flags(use_cloud_connector_lb: false)
    end

    include_examples 'valid endpoint'
  end
end

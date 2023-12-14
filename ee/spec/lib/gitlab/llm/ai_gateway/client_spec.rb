# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::AiGateway::Client, feature_category: :ai_abstraction_layer do
  include StubRequests

  let_it_be(:user) { create(:user) }
  let_it_be(:active_token) { create(:service_access_token, :active) }

  let(:options) { {} }
  let(:expected_request_body) { default_body_params }
  let(:gitlab_global_id) { API::Helpers::GlobalIds::Generator.new.generate(user) }

  let(:expected_access_token) { active_token.token }
  let(:expected_gitlab_realm) { Gitlab::Ai::AccessToken::GITLAB_REALM_SELF_MANAGED }
  let(:expected_gitlab_host_name) { Gitlab.config.gitlab.host }
  let(:expected_instance_id) { gitlab_global_id.first }
  let(:expected_user_id) { gitlab_global_id.second }
  let(:expected_request_headers) do
    {
      'X-Gitlab-Instance-Id' => expected_instance_id,
      'X-Gitlab-Global-User-Id' => expected_user_id,
      'X-Gitlab-Host-Name' => expected_gitlab_host_name,
      'X-Gitlab-Realm' => expected_gitlab_realm,
      'X-Gitlab-Authentication-Type' => 'oidc',
      'Authorization' => "Bearer #{expected_access_token}",
      'Content-Type' => 'application/json'
    }
  end

  let(:default_body_params) do
    {
      prompt_components: [{
        type: described_class::DEFAULT_TYPE,
        metadata: {
          source: described_class::DEFAULT_SOURCE,
          version: Gitlab.version_info.to_s
        },
        payload: {
          content: "anything",
          provider: described_class::DEFAULT_PROVIDER,
          model: described_class::DEFAULT_MODEL
        }
      }]
    }
  end

  let(:expected_response) do
    {
      "response" => "Completion Response",
      "metadata" => {
        "provider" => "anthropic",
        "model" => "claude-2.0",
        "timestamp" => 1000000000 # The number of seconds passed since epoch
      }
    }
  end

  let(:tracking_context) { { request_id: 'uuid', action: 'chat' } }
  let(:response_body) { expected_response.to_json }
  let(:http_status) { 200 }
  let(:response_headers) { { 'Content-Type' => 'application/json' } }

  before do
    stub_request(:post, "#{Gitlab::AiGateway.url}/v1/chat/agent")
      .with(
        body: expected_request_body,
        headers: expected_request_headers
      )
      .to_return(
        status: http_status,
        body: response_body,
        headers: response_headers
      )
  end

  describe '#complete' do
    subject(:complete) do
      described_class.new(user, tracking_context: tracking_context).complete(prompt: 'anything', **options)
    end

    context 'when measuring request success' do
      let(:client) { :ai_gateway }

      it_behaves_like 'measured Llm request'

      context 'when request raises an exception' do
        before do
          allow(Gitlab::HTTP).to receive(:post).and_raise(StandardError)
        end

        it_behaves_like 'measured Llm request with error', StandardError
      end

      context 'when request is retried' do
        let(:http_status) { 429 }

        before do
          stub_const("Gitlab::Llm::Concerns::ExponentialBackoff::INITIAL_DELAY", 0.0)
        end

        it_behaves_like 'measured Llm request with error', Gitlab::Llm::Concerns::ExponentialBackoff::RateLimitError
      end

      context 'when request is retried once' do
        before do
          stub_request(:post, "#{Gitlab::AiGateway.url}/v1/chat/agent")
            .to_return(status: 429, body: '', headers: response_headers)
            .then.to_return(status: 200, body: response_body, headers: response_headers)

          stub_const("Gitlab::Llm::Concerns::ExponentialBackoff::INITIAL_DELAY", 0.0)
        end

        it_behaves_like 'tracks events for AI requests', 2, 4
      end
    end

    it_behaves_like 'tracks events for AI requests', 2, 4

    it 'returns response' do
      expect(Gitlab::HTTP).to receive(:post)
        .with(anything, hash_including(timeout: described_class::DEFAULT_TIMEOUT))
        .and_call_original
      expect(complete.parsed_response).to eq(expected_response)
    end

    context 'when passing stream: true' do
      let(:options) { { stream: true } }
      let(:expected_request_body) { default_body_params }

      it 'does not pass stream: true as we do not want to retrieve SSE events' do
        expect(complete.parsed_response).to eq(expected_response)
      end
    end
  end

  describe '#stream' do
    subject { described_class.new(user, tracking_context: tracking_context).stream(prompt: 'anything', **options) }

    context 'when streaming the request' do
      let(:response_body) { expected_response }
      let(:options) { { stream: true } }
      let(:expected_request_body) { default_body_params.merge(stream: true) }

      context 'when response is successful' do
        let(:expected_response) { 'Hello' }

        it 'provides parsed streamed response' do
          expect { |b| described_class.new(user).stream(prompt: 'anything', **options, &b) }.to yield_with_args('Hello')
        end

        it 'returns response' do
          expect(Gitlab::HTTP).to receive(:post)
            .with(anything, hash_including(timeout: described_class::DEFAULT_TIMEOUT))
            .and_call_original

          expect(described_class.new(user).stream(prompt: 'anything', **options)).to eq("Hello")
        end

        context 'when setting a timeout' do
          let(:options) { { timeout: 50.seconds } }

          it 'uses the timeout for the request' do
            expect(Gitlab::HTTP).to receive(:post)
              .with(anything, hash_including(timeout: 50.seconds))
              .and_call_original

            described_class.new(user).stream(prompt: 'anything', **options)
          end
        end

        it_behaves_like 'tracks events for AI requests', 2, 1
      end

      context 'when response contains multiple events' do
        let(:expected_response) { "Hello World" }

        before do
          allow(Gitlab::HTTP).to receive(:post).and_yield("Hello").and_yield(" ").and_yield("World")
        end

        it 'provides parsed streamed response' do
          expect { |b| described_class.new(user).stream(prompt: 'anything', **options, &b) }
            .to yield_successive_args('Hello', ' ', 'World')
        end

        it 'returns response' do
          expect(described_class.new(user).stream(prompt: 'anything', **options)).to eq(expected_response)
        end
      end
    end
  end
end

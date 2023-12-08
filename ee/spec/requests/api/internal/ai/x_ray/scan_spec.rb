# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::Ai::XRay::Scan, feature_category: :code_suggestions do
  describe 'POST /internal/jobs/:id/x_ray/scan' do
    let_it_be(:add_on_purchase) { create(:gitlab_subscription_add_on_purchase) }
    let_it_be(:namespace) { add_on_purchase.namespace }
    let_it_be(:job) { create(:ci_build, :running, namespace: namespace) }

    let(:ai_gateway_token) { 'ai gateway token' }
    let(:instance_uuid) { "uuid-not-set" }
    let(:hostname) { "localhost" }
    let(:api_url) { "/internal/jobs/#{job.id}/x_ray/scan" }
    let(:headers) { {} }
    let(:params) do
      {
        token: job.token,
        prompt_components: [{ payload: "test" }]
      }
    end

    let(:workhorse_headers) do
      {
        "X-Gitlab-Authentication-Type" => ["oidc"],
        "Authorization" => ["Bearer #{ai_gateway_token}"],
        "Content-Type" => ["application/json"],
        "User-Agent" => [],
        "X-Gitlab-Host-Name" => [hostname],
        "X-Gitlab-Instance-Id" => [instance_uuid],
        "X-Gitlab-Realm" => [gitlab_realm]
      }
    end

    subject(:post_api) do
      post api(api_url), params: params, headers: headers
    end

    context 'when job token is missing' do
      let(:params) do
        {
          prompt_components: [{ payload: "test" }]
        }
      end

      it 'returns Forbidden status' do
        post_api

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    shared_examples 'successful send request via workhorse' do
      it 'sends requests to the XRay libraries AI Gateway endpoint', :aggregate_failures do
        expected_body = params.except(:token)
        expect(Gitlab::Workhorse)
          .to receive(:send_url)
                .with(
                  'https://codesuggestions.gitlab.com/v1/x-ray/libraries',
                  body: expected_body.to_json,
                  method: "POST",
                  headers: workhorse_headers
                )

        post_api

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when on self-managed' do
      let(:gitlab_realm) { "self-managed" }

      it 'checks ServiceAccessToken', :aggregate_failures do
        token_double = instance_double(::Ai::ServiceAccessToken)
        expect(token_double).to receive(:token).and_return(ai_gateway_token)
        expect(::Ai::ServiceAccessToken).to receive_message_chain(:active, :last)
                                              .and_return(token_double)

        post_api
      end

      context 'when ServiceAccessToken is missing' do
        it 'returns UNAUTHORIZED status' do
          post_api

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'when instance has uuid available' do
        let(:instance_uuid) { 'some uuid' }

        before do
          allow(Gitlab::CurrentSettings).to receive(:uuid).and_return(instance_uuid)
          token_double = instance_double(::Ai::ServiceAccessToken, token: ai_gateway_token)
          allow(::Ai::ServiceAccessToken).to receive_message_chain(:active, :last)
                                               .and_return(token_double)
        end

        it_behaves_like 'successful send request via workhorse'
      end

      context 'when instance has custom hostname' do
        let(:hostname) { 'gitlab.local' }

        before do
          stub_config(gitlab: {
            protocol: 'http',
            host: hostname,
            url: "http://#{hostname}",
            relative_url_root: "http://#{hostname}"
          })

          token_double = instance_double(::Ai::ServiceAccessToken, token: ai_gateway_token)
          allow(::Ai::ServiceAccessToken).to receive_message_chain(:active, :last)
                                               .and_return(token_double)
        end

        it_behaves_like 'successful send request via workhorse'
      end
    end

    context 'when on SaaS instance', :saas do
      let(:gitlab_realm) { "saas" }
      let(:workhorse_headers) do
        {
          "X-Gitlab-Authentication-Type" => ["oidc"],
          "Authorization" => ["Bearer #{ai_gateway_token}"],
          "Content-Type" => ["application/json"],
          "User-Agent" => [],
          "X-Gitlab-Host-Name" => [hostname],
          "X-Gitlab-Instance-Id" => [instance_uuid],
          "X-Gitlab-Realm" => [gitlab_realm],
          "X-Gitlab-Saas-Namespace-Ids" => [namespace.id.to_s]
        }
      end

      before do
        allow_next_instance_of(Gitlab::Ai::AccessToken) do |instance|
          allow(instance).to receive(:encoded).and_return(ai_gateway_token)
        end
      end

      it_behaves_like 'successful send request via workhorse'

      context 'when job does not have AI access' do
        let(:job_without_ai_access) { create(:ci_build, :running) }
        let(:api_url) { "/internal/jobs/#{job_without_ai_access.id}/x_ray/scan" }

        let(:params) do
          {
            token: job_without_ai_access.token,
            prompt_components: [{ payload: "test" }]
          }
        end

        it 'returns UNAUTHORIZED status' do
          post_api

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end
  end
end

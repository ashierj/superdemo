# frozen_string_literal: true

# rubocop: disable Gitlab/AvoidGitlabInstanceChecks -- This feature is developed on extremely short notice,
# so I follow existing code patterns in code suggestions AddOn Flow.
module API
  module Internal
    module Ai
      module XRay
        class Scan < ::API::Base
          feature_category :code_suggestions

          helpers ::API::Ci::Helpers::Runner

          before do
            authenticate_job!
            not_found! unless x_ray_enabled_on_instance?
            unauthorized! unless x_ray_available?
          end

          helpers do
            include ::Gitlab::Utils::StrongMemoize

            def x_ray_enabled_on_instance?
              return true if ::Gitlab.org_or_com?

              ::License.feature_available?(:code_suggestions) &&
                ::Gitlab::CurrentSettings.instance_level_code_suggestions_enabled
            end

            def x_ray_available?
              group = current_job.namespace
              return false unless group.namespace_settings.code_suggestions?

              if Gitlab.org_or_com?
                code_suggestions_add_on?(group)
              else
                ai_access_token.present?
              end
            end

            def code_suggestions_add_on?(namespace)
              return true unless ::Feature.enabled?(:purchase_code_suggestions)

              ::GitlabSubscriptions::AddOnPurchase
                .for_code_suggestions
                .by_namespace_id(namespace.id)
                .any?
            end

            def model_gateway_headers(headers, gateway_token)
              {
                'X-Gitlab-Instance-Id' => ::Gitlab::CurrentSettings.uuid.presence || GITLAB_INSTANCE_UUID_NOT_SET,
                'X-Gitlab-Host-Name' => Gitlab.config.gitlab.host,
                'X-Gitlab-Realm' => gitlab_realm,
                'X-Gitlab-Authentication-Type' => 'oidc',
                'Authorization' => "Bearer #{gateway_token}",
                'Content-Type' => 'application/json',
                'User-Agent' => headers["User-Agent"] # Forward the User-Agent on to the model gateway
              }.merge(saas_headers).transform_values { |v| Array(v) }
            end

            def saas_headers
              return {} unless Gitlab.com?

              {
                'X-Gitlab-Saas-Namespace-Ids' => [current_job.namespace.id.to_s]
              }
            end

            def gitlab_realm
              return Gitlab::Ai::AccessToken::GITLAB_REALM_SAAS if Gitlab.org_or_com?

              Gitlab::Ai::AccessToken::GITLAB_REALM_SELF_MANAGED
            end

            def ai_access_token
              ::Ai::ServiceAccessToken.active.last
            end
            strong_memoize_attr :ai_access_token

            def ai_gateway_token
              return ai_access_token.token unless Gitlab.org_or_com?

              Gitlab::Ai::AccessToken.new(
                nil,
                scopes: [:code_suggestions],
                gitlab_realm: gitlab_realm
              ).encoded
            end
          end

          namespace 'internal' do
            resource :jobs do
              params do
                requires :id, type: Integer, desc: %q(Job's ID)
                requires :token, type: String, desc: %q(Job's authentication token)
              end
              post ':id/x_ray/scan' do
                workhorse_headers =
                  Gitlab::Workhorse.send_url(
                    File.join(::CodeSuggestions::Tasks::Base.base_url, 'v1', 'x-ray', 'libraries'),
                    body: params.except(:token, :id).to_json,
                    headers: model_gateway_headers(headers, ai_gateway_token),
                    method: "POST"
                  )

                header(*workhorse_headers)
                status :ok
              end
            end
          end
        end
      end
    end
  end
end
# rubocop: enable Gitlab/AvoidGitlabInstanceChecks

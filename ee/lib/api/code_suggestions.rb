# frozen_string_literal: true

module API
  class CodeSuggestions < ::API::Base
    include APIGuard

    feature_category :code_suggestions

    helpers ::API::Helpers::GlobalIds

    # a limit used for overall body size when forwarding request to ai-assist, overall size should not be bigger than
    # summary of limits on accepted parameters
    # (https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#completions)
    MAX_BODY_SIZE = 500_000
    MAX_CONTENT_SIZE = 400_000

    allow_access_with_scope :ai_features

    before do
      authenticate!

      not_found! unless Feature.enabled?(:code_suggestions_tokens_api, type: :ops)
      unauthorized! unless user_allowed?
    end

    helpers do
      def user_allowed?
        current_user.can?(:access_code_suggestions) && access_code_suggestions_when_proxied_to_saas?
      end

      def model_gateway_headers(headers, gateway_token)
        telemetry_headers = headers.select { |k| /\Ax-gitlab-cs-/i.match?(k) }

        instance_id, user_id = global_instance_and_user_id_for(current_user)
        {
          'X-Gitlab-Instance-Id' => instance_id,
          'X-Gitlab-Global-User-Id' => user_id,
          'X-Gitlab-Host-Name' => Gitlab.config.gitlab.host,
          'X-Gitlab-Realm' => gitlab_realm,
          'X-Gitlab-Authentication-Type' => 'oidc',
          'Authorization' => "Bearer #{gateway_token}",
          'Content-Type' => 'application/json',
          'User-Agent' => headers["User-Agent"] # Forward the User-Agent on to the model gateway
        }.merge(telemetry_headers).merge(saas_headers).transform_values { |v| Array(v) }
      end

      def saas_headers
        return {} unless Gitlab.com?

        {
          'X-Gitlab-Saas-Namespace-Ids' => current_user.code_suggestions_add_on_available_namespace_ids.join(',')
        }
      end

      # In case the request was proxied from the self-managed instance,
      # we have an extra check on Gitlab.com if FF is enabled for self-managed admin.
      # The FF is used for gradual rollout for handpicked self-managed customers interested to use code suggestions.
      #
      # NOTE: This code path is being phased out as part of working towards GA for code suggestions.
      # See https://gitlab.com/groups/gitlab-org/-/epics/11114
      def access_code_suggestions_when_proxied_to_saas?
        proxied = proxied?

        raise 'Proxying is only supported under .org or .com' if proxied && !Gitlab.org_or_com?

        !proxied || Feature.enabled?(:code_suggestions_for_instance_admin_enabled, current_user)
      end

      def proxied?
        !!request.headers['User-Agent']&.starts_with?('gitlab-workhorse')
      end

      def gitlab_realm
        # NOTE: This code path is being phased out as part of working towards GA for code suggestions.
        # See https://gitlab.com/groups/gitlab-org/-/epics/11114
        return Gitlab::Ai::AccessToken::GITLAB_REALM_SELF_MANAGED if proxied?

        return Gitlab::Ai::AccessToken::GITLAB_REALM_SAAS if Gitlab.org_or_com?

        Gitlab::Ai::AccessToken::GITLAB_REALM_SELF_MANAGED
      end
    end

    namespace 'code_suggestions' do
      resources :tokens do
        desc 'Create an access token' do
          detail 'Creates an access token to access Code Suggestions.'
          success Entities::CodeSuggestionsAccessToken
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
        end
        post do
          not_found! unless Gitlab.org_or_com?

          Gitlab::Tracking.event(
            'API::CodeSuggestions',
            :authenticate,
            user: current_user,
            label: 'code_suggestions'
          )

          Gitlab::InternalEvents.track_event(
            'code_suggestions_authenticate',
            user: current_user
          )

          token = Gitlab::Ai::AccessToken.new(current_user, scopes: [:code_suggestions], gitlab_realm: gitlab_realm)
          present token, with: Entities::CodeSuggestionsAccessToken
        end
      end

      resources :completions do
        params do
          requires :current_file, type: Hash do
            requires :file_name, type: String, limit: 255, desc: 'The name of the current file'
            requires :content_above_cursor, type: String, limit: MAX_CONTENT_SIZE, desc: 'The content above cursor'
            optional :content_below_cursor, type: String, limit: MAX_CONTENT_SIZE, desc: 'The content below cursor'
          end
          optional :intent, type: String, values:
            [
              ::CodeSuggestions::InstructionsExtractor::INTENT_COMPLETION,
              ::CodeSuggestions::InstructionsExtractor::INTENT_GENERATION
            ],
            desc: 'The intent of the completion request, current options are "completion" or "generation"'
          optional :stream, type: Boolean, default: false, desc: 'The option to stream code completion response'
        end
        post do
          if Gitlab.org_or_com?
            forbidden! unless ::Feature.enabled?(:code_suggestions_completion_api, current_user)

            if ::Feature.enabled?(:purchase_code_suggestions)
              not_found! unless current_user.code_suggestions_add_on_available? # rubocop: disable Style/SoleNestedConditional -- Feature Flag shouldn't be checked in the same condition.
            end

            token = Gitlab::Ai::AccessToken.new(
              current_user,
              scopes: [:code_suggestions],
              gitlab_realm: gitlab_realm
            ).encoded
          else
            code_suggestions_token = ::Ai::ServiceAccessToken.active.last
            unauthorized! if code_suggestions_token.nil?

            token = code_suggestions_token.token
          end

          check_rate_limit!(:code_suggestions_api_endpoint, scope: current_user) do
            Gitlab::InternalEvents.track_event(
              'code_suggestions_rate_limit_exceeded',
              user: current_user
            )

            render_api_error!({ error: _('This endpoint has been requested too many times. Try again later.') }, 429)
          end

          task = ::CodeSuggestions::TaskFactory.new(
            current_user,
            params: declared_params(params),
            unsafe_passthrough_params: params.except(:private_token)
          ).task

          body = task.body
          file_too_large! if body.size > MAX_BODY_SIZE

          workhorse_headers =
            Gitlab::Workhorse.send_url(
              task.endpoint,
              body: body,
              headers: model_gateway_headers(headers, token),
              method: "POST"
            )

          header(*workhorse_headers)

          status :ok
          body ''
        end
      end
    end
  end
end

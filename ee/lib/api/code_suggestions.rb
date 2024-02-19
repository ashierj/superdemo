# frozen_string_literal: true

module API
  class CodeSuggestions < ::API::Base
    include APIGuard

    feature_category :code_suggestions

    helpers ::API::Helpers::CloudConnector

    # a limit used for overall body size when forwarding request to ai-assist, overall size should not be bigger than
    # summary of limits on accepted parameters
    # (https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#completions)
    MAX_BODY_SIZE = 500_000
    MAX_CONTENT_SIZE = 400_000

    allow_access_with_scope :ai_features

    before do
      authenticate!

      not_found! unless Feature.enabled?(:code_suggestions_tokens_api, type: :ops)
      unauthorized! unless current_user.can?(:access_code_suggestions)
    end

    helpers do
      def model_gateway_headers(headers, gateway_token)
        telemetry_headers = headers.select { |k| /\Ax-gitlab-cs-/i.match?(k) }

        {
          'X-Gitlab-Host-Name' => Gitlab.config.gitlab.host,
          'X-Gitlab-Authentication-Type' => 'oidc',
          'Authorization' => "Bearer #{gateway_token}",
          'Content-Type' => 'application/json',
          'User-Agent' => headers["User-Agent"] # Forward the User-Agent on to the model gateway
        }.merge(telemetry_headers).merge(saas_headers).merge(cloud_connector_headers(current_user))
          .transform_values { |v| Array(v) }
      end

      def saas_headers
        return {} unless Gitlab.com?

        {
          'X-Gitlab-Saas-Namespace-Ids' => current_user.namespaces_ids_with_code_suggestions_enabled.join(','),
          'X-Gitlab-Saas-Duo-Pro-Namespace-Ids' => current_user
                                                     .duo_pro_add_on_available_namespace_ids
                                                     .join(',')
        }
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

          token = Gitlab::CloudConnector::SelfIssuedToken.new(
            current_user, scopes: [:code_suggestions], gitlab_realm: gitlab_realm)
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
          optional :project_path, type: String, desc: 'The path of the project',
            documentation: { example: 'namespace/project' }
        end
        post do
          # rubocop: disable Style/SoleNestedConditional -- Feature Flag shouldn't be checked in the same condition.
          if Gitlab.org_or_com?
            if ::Feature.enabled?(:purchase_code_suggestions)
              not_found! unless current_user.duo_pro_add_on_available?
            end
          end
          # rubocop: enable Style/SoleNestedConditional

          token = ::CloudConnector::AccessService.new.access_token([:code_suggestions], gitlab_realm)

          unauthorized! if token.nil?

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

          Gitlab::InternalEvents.track_event(
            'code_suggestions_requested',
            user: current_user
          )

          workhorse_headers =
            Gitlab::Workhorse.send_url(
              task.endpoint,
              body: body,
              headers: model_gateway_headers(headers, token),
              method: "POST",
              timeouts: { read: 55 }
            )

          header(*workhorse_headers)

          status :ok
          body ''
        end
      end

      resources :enabled do
        desc 'Code suggestions enabled for a project' do
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: '403 Code Suggestions Disabled' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :project_path, type: String, desc: 'The path of the project',
            documentation: { example: 'namespace/project' }
        end

        post do
          path = declared_params[:project_path]

          not_found! if path.empty?

          projects = ::ProjectsFinder.new(params: { full_paths: [path] }, current_user: current_user).execute

          not_found! if projects.none?

          forbidden! unless projects.first.code_suggestions_enabled?

          status :ok
        end
      end
    end
  end
end

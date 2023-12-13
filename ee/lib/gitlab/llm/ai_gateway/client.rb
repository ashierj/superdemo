# frozen_string_literal: true

module Gitlab
  module Llm
    module AiGateway
      class Client
        include ::Gitlab::Llm::Concerns::ExponentialBackoff
        include ::Gitlab::Llm::Concerns::EventTracking
        include ::API::Helpers::GlobalIds
        include ::Gitlab::Utils::StrongMemoize

        DEFAULT_PROVIDER = 'anthropic'
        DEFAULT_MODEL = 'claude-2.0'
        DEFAULT_TIMEOUT = 30.seconds
        DEFAULT_TYPE = 'prompt'
        DEFAULT_SOURCE = 'GitLab EE'

        ALLOWED_PAYLOAD_PARAM_KEYS = %i[temperature max_tokens_to_sample stop_sequences].freeze

        def initialize(user, tracking_context: {})
          @user = user
          @tracking_context = tracking_context
          @logger = Gitlab::Llm::Logger.build
        end

        def complete(prompt:, **options)
          return unless enabled?

          # We do not allow to set `stream` because the separate `#stream` method should be used for streaming.
          # The reason is that streaming the response would not work with the exponential backoff mechanism.
          response = retry_with_exponential_backoff do
            perform_completion_request(prompt: prompt, options: options.except(:stream))
          end

          track_prompt_size(token_size(prompt))
          track_response_size(token_size(response["response"]))

          response
        end

        def stream(prompt:, **options)
          return unless enabled?

          response_body = ""

          perform_completion_request(prompt: prompt, options: options.merge(stream: true)) do |chunk|
            response_body += chunk

            yield chunk if block_given?
          end

          track_prompt_size(token_size(prompt))
          track_response_size(token_size(response_body))

          response_body
        end

        private

        attr_reader :user, :logger, :tracking_context

        def perform_completion_request(prompt:, options:)
          logger.info(message: "Performing request to AI Gateway", options: options)
          timeout = options.delete(:timeout) || DEFAULT_TIMEOUT

          response = Gitlab::HTTP.post(
            URI.join(Gitlab::AiGateway.url, '/v1/chat/agent'),
            headers: request_headers,
            body: request_body(prompt: prompt, options: options).to_json,
            timeout: timeout,
            allow_local_requests: true,
            stream_body: options.fetch(:stream, false)
          ) do |fragment|
            yield fragment if block_given?
          end

          logger.info_or_debug(user, message: "Received response from AI Gateway", response: response)

          response
        end

        def enabled?
          access_token.present?
        end

        def request_headers
          instance_id, user_id = global_instance_and_user_id_for(user)
          {
            'X-Gitlab-Instance-Id' => instance_id,
            'X-Gitlab-Global-User-Id' => user_id,
            'X-Gitlab-Host-Name' => Gitlab.config.gitlab.host,
            'X-Gitlab-Realm' => gitlab_realm,
            'X-Gitlab-Authentication-Type' => 'oidc',
            'Authorization' => "Bearer #{access_token}",
            'Content-Type' => 'application/json'
          }
        end

        def gitlab_realm
          return Gitlab::Ai::AccessToken::GITLAB_REALM_SAAS if Gitlab.org_or_com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- To align with ee/lib/api/code_suggestions.rb.

          Gitlab::Ai::AccessToken::GITLAB_REALM_SELF_MANAGED
        end

        def access_token
          if Gitlab.org_or_com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- To align with ee/lib/api/code_suggestions.rb.
            Gitlab::Ai::AccessToken.new(
              user,
              scopes: [:duo_chat],
              gitlab_realm: gitlab_realm
            ).encoded
          else
            ::Ai::ServiceAccessToken.active.last&.token
          end
        end
        strong_memoize_attr :access_token

        def request_body(prompt:, options: {})
          {
            prompt_components: [{
              type: DEFAULT_TYPE,
              metadata: {
                source: DEFAULT_SOURCE,
                version: Gitlab.version_info.to_s
              },
              payload: {
                content: prompt,
                provider: DEFAULT_PROVIDER,
                model: options.fetch(:model, DEFAULT_MODEL)
              }.merge(payload_params(options))
            }],
            stream: options.fetch(:stream, false)
          }
        end

        def payload_params(options)
          params = options.slice(*ALLOWED_PAYLOAD_PARAM_KEYS)

          return {} if params.empty?

          { params: params }
        end

        def token_size(content)
          # Anthropic's APIs don't send used tokens as part of the response, so
          # instead we estimate the number of tokens based on typical token size -
          # one token is roughly 4 chars.
          content.to_s.size / 4
        end
      end
    end
  end
end

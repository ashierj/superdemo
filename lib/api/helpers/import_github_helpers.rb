# frozen_string_literal: true

module API
  module Helpers
    module ImportGithubHelpers
      def client
        @client ||= if Feature.enabled?(:remove_legacy_github_client)
                      Gitlab::GithubImport::Client.new(params[:personal_access_token], host: params[:github_hostname])
                    else
                      Gitlab::LegacyGithubImport::Client.new(params[:personal_access_token], **client_options)
                    end
      end

      def access_params
        {
          github_access_token: params[:personal_access_token],
          additional_access_tokens: params[:additional_access_tokens]
        }
      end

      def client_options
        { host: params[:github_hostname] }
      end

      def provider
        :github
      end

      def provider_unauthorized
        error!("Access denied to your #{Gitlab::ImportSources.title(provider.to_s)} account.", 401)
      end

      def too_many_requests
        error!('Too Many Requests', 429)
      end
    end
  end
end

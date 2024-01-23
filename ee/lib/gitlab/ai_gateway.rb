# frozen_string_literal: true

module Gitlab
  module AiGateway
    # Going forward, we should route this through cloud.gitlab.com.
    LEGACY_URL = 'https://codesuggestions.gitlab.com'
    private_constant :LEGACY_URL

    def self.url
      if Feature.enabled?('use_cloud_connector_lb', type: :experiment)
        ENV['AI_GATEWAY_URL'] || "#{::CloudConnector::Config.base_url}/ai"
      else
        # TODO: Rename to `AI_GATEWAY_URL`
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/434671
        #
        ENV['CODE_SUGGESTIONS_BASE_URL'] || LEGACY_URL
      end
    end
  end
end

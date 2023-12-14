# frozen_string_literal: true

module Gitlab
  module AiGateway
    DEFAULT_URL = 'https://codesuggestions.gitlab.com'

    def self.url
      # TODO: Rename to `AI_GATEWAY_URL`
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/434671
      ENV['CODE_SUGGESTIONS_BASE_URL'] || DEFAULT_URL
    end
  end
end

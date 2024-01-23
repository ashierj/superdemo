# frozen_string_literal: true

module Gitlab
  module AiGateway
    def self.url
      ENV['AI_GATEWAY_URL'] || "#{::CloudConnector::Config.base_url}/ai"
    end
  end
end

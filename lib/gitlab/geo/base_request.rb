module Gitlab
  module Geo
    class BaseRequest
      GITLAB_GEO_AUTH_TOKEN_TYPE = 'GL-Geo'.freeze

      attr_reader :request_data

      def initialize(request_data = {})
        @request_data = request_data
      end

      def headers
        {
          'Authorization' => geo_auth_token(request_data)
        }
      end

      private

      def geo_auth_token(message)
        geo_node = requesting_node
        return unless geo_node

        token = JSONWebToken::HMACToken.new(geo_node.secret_access_key)
        token[:data] = message.to_json

        "#{GITLAB_GEO_AUTH_TOKEN_TYPE} #{geo_node.access_key}:#{token.encoded}"
      end

      def requesting_node
        Gitlab::Geo.current_node
      end
    end
  end
end

# frozen_string_literal: true

module API
  module Helpers
    module CloudConnector
      include ::API::Helpers::GlobalIds

      def cloud_connector_headers(user)
        instance_id, user_id = global_instance_and_user_id_for(user)

        {
          'X-Gitlab-Instance-Id' => instance_id,
          'X-Gitlab-Global-User-Id' => user_id,
          'X-Gitlab-Realm' => gitlab_realm
        }
      end

      def gitlab_realm
        return Gitlab::CloudConnector::SelfIssuedToken::GITLAB_REALM_SAAS if Gitlab.org_or_com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- To align with ee/lib/api/code_suggestions.rb.

        Gitlab::CloudConnector::SelfIssuedToken::GITLAB_REALM_SELF_MANAGED
      end
    end
  end
end

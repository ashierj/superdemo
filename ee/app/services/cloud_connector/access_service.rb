# frozen_string_literal: true

module CloudConnector
  class AccessService
    # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- currently, we don't have dedicated SM/SaaS features
    # will be addressed in https://gitlab.com/gitlab-org/gitlab/-/issues/437725
    def access_token(scopes, gitlab_realm)
      Gitlab.org_or_com? ? saas_token(scopes, gitlab_realm) : self_managed_token
    end
    # rubocop:enable Gitlab/AvoidGitlabInstanceChecks

    private

    def self_managed_token
      ::CloudConnector::ServiceAccessToken.active.last&.token
    end

    def saas_token(scopes, gitlab_realm)
      Gitlab::CloudConnector::SelfIssuedToken.new(
        nil,
        scopes: scopes,
        gitlab_realm: gitlab_realm
      ).encoded
    end
  end
end

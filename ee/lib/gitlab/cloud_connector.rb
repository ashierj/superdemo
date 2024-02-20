# frozen_string_literal: true

module Gitlab
  module CloudConnector
    GITLAB_REALM_SAAS = 'saas'
    GITLAB_REALM_SELF_MANAGED = 'self-managed'

    def self.gitlab_realm
      Gitlab.org_or_com? ? GITLAB_REALM_SAAS : GITLAB_REALM_SELF_MANAGED # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- Will be addressed in https://gitlab.com/gitlab-org/gitlab/-/issues/437725
    end
  end
end

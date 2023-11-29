# frozen_string_literal: true

module EE
  module ProtectedBranchAccess
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    private

    def group_access_allowed?(current_user)
      # For protected branches, only groups that are invited to the project
      # can granted push and merge access. This feature does not work groups
      # that are ancestors of the project.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/427486.
      # Hence, we only consider the role of the user in the group limited by
      # the max role of the project_group_link.
      #
      # We do not use the access level provided by direct membership to the project
      # or inherited through ancestor groups of the project.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/423835

      project_group_link = project.project_group_links.find_by(group: group)
      return false unless project_group_link.present?
      return false if project_group_link.group_access < ::Gitlab::Access::DEVELOPER

      group.member?(current_user, ::Gitlab::Access::DEVELOPER)
    end
  end
end

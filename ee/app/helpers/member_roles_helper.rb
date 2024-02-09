# frozen_string_literal: true

module MemberRolesHelper
  def manage_member_roles_path(source)
    root_group = source&.root_ancestor
    return unless root_group&.custom_roles_enabled?

    if gitlab_com_subscription? && can?(current_user, :admin_group_member, root_group)
      group_settings_roles_and_permissions_path(root_group)
    elsif current_user&.can_admin_all_resources?
      admin_application_settings_roles_and_permissions_path
    end
  end
end

# frozen_string_literal: true

module WorkItemsHelper
  def work_items_index_data(resource_parent)
    {
      full_path: resource_parent.full_path,
      issues_list_path:
        resource_parent.is_a?(Group) ? issues_group_path(resource_parent) : project_issues_path(resource_parent),
      register_path: new_user_registration_path(redirect_to_referer: 'yes'),
      sign_in_path: new_session_path(:user, redirect_to_referer: 'yes'),
      new_comment_template_path: profile_comment_templates_path,
      report_abuse_path: add_category_abuse_reports_path
    }
  end

  def work_items_list_data(group)
    {
      full_path: group.full_path
    }
  end
end

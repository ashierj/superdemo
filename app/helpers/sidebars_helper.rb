# frozen_string_literal: true

module SidebarsHelper
  include MergeRequestsHelper
  include Nav::NewDropdownHelper

  def sidebar_tracking_attributes_by_object(object)
    sidebar_attributes_for_object(object).fetch(:tracking_attrs, {})
  end

  def sidebar_qa_selector(object)
    sidebar_attributes_for_object(object).fetch(:sidebar_qa_selector, nil)
  end

  def scope_qa_menu_item(object)
    sidebar_attributes_for_object(object).fetch(:scope_qa_menu_item, nil)
  end

  def scope_avatar_classes(object)
    %w[avatar-container rect-avatar s32].tap do |klasses|
      klass = sidebar_attributes_for_object(object).fetch(:scope_avatar_class, nil)
      klasses << klass if klass
    end
  end

  def organization_sidebar_context(organization, user, **args)
    Sidebars::Context.new(container: organization, current_user: user, **args)
  end

  def project_sidebar_context(project, user, current_ref, ref_type: nil, **args)
    context_data = project_sidebar_context_data(project, user, current_ref, ref_type: ref_type)
    Sidebars::Projects::Context.new(**context_data, **args)
  end

  def group_sidebar_context(group, user, **args)
    context_data = group_sidebar_context_data(group, user)

    Sidebars::Groups::Context.new(**context_data, **args)
  end

  def your_work_sidebar_context(user, **args)
    context_data = your_work_context_data(user)

    Sidebars::Context.new(**context_data, **args)
  end

  def super_sidebar_context(user, group:, project:, panel:, panel_type:) # rubocop:disable Metrics/AbcSize
    return super_sidebar_logged_out_context(panel: panel, panel_type: panel_type) unless user

    super_sidebar_logged_in_context(user, group: group, project: project, panel: panel, panel_type: panel_type)
  end

  def super_sidebar_logged_out_context(panel:, panel_type:) # rubocop:disable Metrics/AbcSize
    {
      is_logged_in: false,
      context_switcher_links: context_switcher_links,
      current_menu_items: panel.super_sidebar_menu_items,
      current_context_header: panel.super_sidebar_context_header,
      support_path: support_url,
      display_whats_new: display_whats_new?,
      whats_new_most_recent_release_items_count: whats_new_most_recent_release_items_count,
      whats_new_version_digest: whats_new_version_digest,
      show_version_check: show_version_check?,
      gitlab_version: Gitlab.version_info,
      gitlab_version_check: gitlab_version_check,
      search: search_data,
      panel_type: panel_type,
      shortcut_links: shortcut_links
    }
  end

  def super_sidebar_logged_in_context(user, group:, project:, panel:, panel_type:) # rubocop:disable Metrics/AbcSize
    super_sidebar_logged_out_context(panel: panel, panel_type: panel_type).merge({
      is_logged_in: true,
      name: user.name,
      username: user.username,
      avatar_url: user.avatar_url,
      has_link_to_profile: current_user_menu?(:profile),
      link_to_profile: user_path(user),
      logo_url: current_appearance&.header_logo_path,
      status: user_status_menu_data(user),
      settings: {
        has_settings: current_user_menu?(:settings),
        profile_path: profile_path,
        profile_preferences_path: profile_preferences_path
      },
      user_counts: {
        assigned_issues: user.assigned_open_issues_count,
        assigned_merge_requests: user.assigned_open_merge_requests_count,
        review_requested_merge_requests: user.review_requested_open_merge_requests_count,
        todos: user.todos_pending_count,
        last_update: time_in_milliseconds
      },
      can_sign_out: current_user_menu?(:sign_out),
      sign_out_link: destroy_user_session_path,
      issues_dashboard_path: issues_dashboard_path(assignee_username: user.username),
      todos_dashboard_path: dashboard_todos_path,
      create_new_menu_groups: create_new_menu_groups(group: group, project: project),
      merge_request_menu: create_merge_request_menu(user),
      projects_path: dashboard_projects_path,
      groups_path: dashboard_groups_path,
      gitlab_com_but_not_canary: Gitlab.com_but_not_canary?,
      gitlab_com_and_canary: Gitlab.com_and_canary?,
      canary_toggle_com_url: Gitlab::Saas.canary_toggle_com_url,
      current_context: super_sidebar_current_context(project: project, group: group),
      pinned_items: user.pinned_nav_items[panel_type] || super_sidebar_default_pins(panel_type),
      update_pins_url: pins_path,
      is_impersonating: impersonating?,
      stop_impersonation_path: admin_impersonation_path,
      shortcut_links: shortcut_links(user: user, project: project),
      track_visits_path: track_namespace_visits_path
    })
  end

  def super_sidebar_nav_panel(
    nav: nil, project: nil, user: nil, group: nil, current_ref: nil, ref_type: nil,
    viewed_user: nil, organization: nil)
    context_adds = { route_is_active: method(:active_nav_link?), is_super_sidebar: true }
    panel = case nav
            when 'project'
              context = project_sidebar_context(project, user, current_ref, ref_type: ref_type, **context_adds)
              Sidebars::Projects::SuperSidebarPanel.new(context)
            when 'group'
              context = group_sidebar_context(group, user, **context_adds)
              Sidebars::Groups::SuperSidebarPanel.new(context)
            when 'profile'
              context = Sidebars::Context.new(current_user: user, container: user, **context_adds)
              Sidebars::UserSettings::Panel.new(context)
            when 'user_profile'
              context = Sidebars::Context.new(current_user: user, container: viewed_user, **context_adds)
              Sidebars::UserProfile::Panel.new(context)
            when 'explore'
              Sidebars::Explore::Panel.new(Sidebars::Context.new(current_user: user, container: nil, **context_adds))
            when 'search'
              context = Sidebars::Context.new(current_user: user, container: nil, **context_adds)
              Sidebars::Search::Panel.new(context)
            when 'admin'
              Sidebars::Admin::Panel.new(Sidebars::Context.new(current_user: user, container: nil, **context_adds))
            when 'organization'
              context = organization_sidebar_context(organization, user, **context_adds)
              Sidebars::Organizations::SuperSidebarPanel.new(context)
            when 'your_work'
              context = your_work_sidebar_context(user, **context_adds)
              Sidebars::YourWork::Panel.new(context)
            end

    # We only return the panel if any menu item is rendered, otherwise fallback
    return panel if panel&.render?

    # Fallback menu "Your work" for logged-in users, "Explore" for logged-out
    if user
      context = your_work_sidebar_context(user, **context_adds)
      Sidebars::YourWork::Panel.new(context)
    else
      Sidebars::Explore::Panel.new(Sidebars::Context.new(current_user: nil, container: nil, **context_adds))
    end
  end

  def command_palette_data(project: nil)
    return {} unless project&.repo_exists?
    return {} if project.empty_repo?

    {
      project_files_url: project_files_path(project, project.default_branch, format: :json),
      project_blob_url: project_blob_path(project, project.default_branch)
    }
  end

  private

  def search_data
    {
      search_path: search_path,
      issues_path: issues_dashboard_path,
      mr_path: merge_requests_dashboard_path,
      autocomplete_path: search_autocomplete_path,
      search_context: header_search_context
    }
  end

  def user_status_menu_data(user)
    {
      can_update: can?(user, :update_user_status, user),
      busy: user.status&.busy?,
      customized: user.status&.customized?,
      availability: user.status&.availability.to_s,
      emoji: user.status&.emoji,
      message_html: user.status&.message_html&.html_safe,
      message: user.status&.message,
      clear_after: user_clear_status_at(user)
    }
  end

  def create_new_menu_groups(group:, project:)
    new_dropdown_sections = new_dropdown_view_model(group: group, project: project)[:menu_sections]
    show_headers = new_dropdown_sections.length > 1
    new_dropdown_sections.map do |section|
      {
        name: show_headers ? section[:title] : '',
        items: section[:menu_items].map do |item|
                 {
                   text: item[:title],
                   href: item[:href].presence,
                   component: item[:component].presence,
                   extraAttrs: {
                     'data-track-label': item[:id],
                     'data-track-action': 'click_link',
                     'data-track-property': 'nav_create_menu',
                     'data-testid': 'create_menu_item',
                     'data-qa-create-menu-item': item[:id]
                   }
                 }
               end
      }
    end
  end

  def create_merge_request_menu(user)
    [
      {
        name: _('Merge requests'),
        items: [
          {
            text: _('Assigned'),
            href: merge_requests_dashboard_path(assignee_username: user.username),
            count: user.assigned_open_merge_requests_count,
            userCount: 'assigned_merge_requests',
            extraAttrs: {
              'data-track-action': 'click_link',
              'data-track-label': 'merge_requests_assigned',
              'data-track-property': 'nav_core_menu',
              class: 'dashboard-shortcuts-merge_requests'
            }
          },
          {
            text: _('Review requests'),
            href: merge_requests_dashboard_path(reviewer_username: user.username),
            count: user.review_requested_open_merge_requests_count,
            userCount: 'review_requested_merge_requests',
            extraAttrs: {
              'data-track-action': 'click_link',
              'data-track-label': 'merge_requests_to_review',
              'data-track-property': 'nav_core_menu',
              class: 'dashboard-shortcuts-review_requests'
            }
          }
        ]
      }
    ]
  end

  def sidebar_attributes_for_object(object)
    case object
    when Project
      sidebar_project_attributes
    when Group
      sidebar_group_attributes
    when User
      sidebar_user_attributes
    else
      {}
    end
  end

  def sidebar_project_attributes
    {
      tracking_attrs: sidebar_project_tracking_attrs,
      sidebar_qa_selector: 'project_sidebar',
      scope_qa_menu_item: 'Project scope',
      scope_avatar_class: 'project_avatar'
    }
  end

  def sidebar_group_attributes
    {
      tracking_attrs: sidebar_group_tracking_attrs,
      sidebar_qa_selector: 'group_sidebar',
      scope_qa_menu_item: 'Group scope',
      scope_avatar_class: 'group_avatar'
    }
  end

  def sidebar_user_attributes
    {
      tracking_attrs: sidebar_user_profile_tracking_attrs
    }
  end

  def sidebar_project_tracking_attrs
    tracking_attrs('projects_side_navigation', 'render', 'projects_side_navigation')
  end

  def sidebar_group_tracking_attrs
    tracking_attrs('groups_side_navigation', 'render', 'groups_side_navigation')
  end

  def sidebar_user_profile_tracking_attrs
    tracking_attrs('user_side_navigation', 'render', 'user_side_navigation')
  end

  def project_sidebar_context_data(project, user, current_ref, ref_type: nil)
    {
      current_user: user,
      container: project,
      current_ref: current_ref,
      ref_type: ref_type,
      jira_issues_integration: project_jira_issues_integration?,
      can_view_pipeline_editor: can_view_pipeline_editor?(project),
      show_cluster_hint: show_gke_cluster_integration_callout?(project)
    }
  end

  def group_sidebar_context_data(group, user)
    {
      current_user: user,
      container: group
    }
  end

  def your_work_context_data(user)
    {
      current_user: user,
      container: user,
      show_security_dashboard: false
    }
  end

  def super_sidebar_current_context(project: nil, group: nil)
    if project&.persisted?
      return {
        namespace: 'projects',
        item: {
          id: project.id,
          name: project.name,
          namespace: project.full_name,
          webUrl: project_path(project),
          avatarUrl: project.avatar_url
        }
      }
    end

    if group&.persisted?
      return {
        namespace: 'groups',
        item: {
          id: group.id,
          name: group.name,
          namespace: group.full_name,
          webUrl: group_path(group),
          avatarUrl: group.avatar_url
        }
      }
    end

    {}
  end

  def context_switcher_links
    links = [
      ({ title: s_('Navigation|Your work'), link: root_path, icon: 'work' } if current_user),
      { title: s_('Navigation|Explore'), link: explore_root_path, icon: 'compass' },
      ({ title: s_('Navigation|Profile'), link: profile_path, icon: 'profile' } if current_user),
      ({ title: s_('Navigation|Preferences'), link: profile_preferences_path, icon: 'preferences' } if current_user)
    ]

    # Usually, using current_user.admin? is discouraged because it does not
    # check for admin mode, but since here we want to check admin? and admin mode
    # separately, we'll have to ignore the cop rule.
    # rubocop: disable Cop/UserAdmin
    if current_user&.can_admin_all_resources?
      links.append(
        { title: s_('Navigation|Admin Area'), link: admin_root_path, icon: 'admin' }
      )
    end

    if Gitlab::CurrentSettings.admin_mode
      if header_link?(:admin_mode)
        links.append(
          {
            title: s_('Navigation|Leave admin mode'),
            link: destroy_admin_session_path,
            icon: 'lock-open',
            data_method: 'post'
          }
        )
      elsif current_user&.admin?
        links.append(
          {
            title: s_('Navigation|Enter admin mode'),
            link: new_admin_session_path,
            icon: 'lock'
          }
        )
      end
    end
    # rubocop: enable Cop/UserAdmin

    links.compact
  end

  def impersonating?
    !!session[:impersonator_id]
  end

  def shortcut_links_anonymous
    [
      {
        title: _('Snippets'),
        href: explore_snippets_path,
        css_class: 'dashboard-shortcuts-snippets'
      },
      {
        title: _('Groups'),
        href: explore_groups_path,
        css_class: 'dashboard-shortcuts-groups'
      },
      {
        title: _('Projects'),
        href: explore_projects_path,
        css_class: 'dashboard-shortcuts-projects'
      }
    ]
  end

  def shortcut_links(user: nil, project: nil)
    return shortcut_links_anonymous unless user

    shortcut_links = [
      {
        title: _('Milestones'),
        href: dashboard_milestones_path,
        css_class: 'dashboard-shortcuts-milestones'
      },
      {
        title: _('Snippets'),
        href: dashboard_snippets_path,
        css_class: 'dashboard-shortcuts-snippets'
      },
      {
        title: _('Activity'),
        href: activity_dashboard_path,
        css_class: 'dashboard-shortcuts-activity'
      },
      {
        title: _('Groups'),
        href: dashboard_groups_path,
        css_class: 'dashboard-shortcuts-groups'
      },
      {
        title: _('Projects'),
        href: dashboard_projects_path,
        css_class: 'dashboard-shortcuts-projects'
      }
    ]

    if project&.persisted? && can?(user, :create_issue, project)
      shortcut_links << {
        title: _('Create a new issue'),
        href: new_project_issue_path(project),
        css_class: 'shortcuts-new-issue'
      }
    end

    shortcut_links
  end

  def super_sidebar_default_pins(panel_type)
    case panel_type
    when 'project'
      [:project_issue_list, :project_merge_request_list]
    when 'group'
      [:group_issue_list, :group_merge_request_list]
    else
      []
    end
  end
end

SidebarsHelper.prepend_mod_with('SidebarsHelper')

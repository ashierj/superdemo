# frozen_string_literal: true

module ProjectsHelper
  include Gitlab::Utils::StrongMemoize
  include CompareHelper
  include Gitlab::Allowable

  def project_incident_management_setting
    @project_incident_management_setting ||= @project.incident_management_setting ||
      @project.build_incident_management_setting
  end

  def link_to_project(project)
    link_to namespace_project_path(namespace_id: project.namespace, id: project), title: h(project.name), class: 'gl-link gl-text-truncate' do
      title = content_tag(:span, project.name, class: 'project-name')

      if project.namespace
        namespace = content_tag(:span, "#{project.namespace.human_name} / ", class: 'namespace-name')
        title = namespace + title
      end

      title
    end
  end

  def link_to_member_avatar(author, opts = {})
    default_opts = { size: 16 }
    opts = default_opts.merge(opts)

    classes = %W[avatar avatar-inline s#{opts[:size]}]
    classes << opts[:avatar_class] if opts[:avatar_class]

    avatar = avatar_icon_for_user(author, opts[:size])

    image_tag(avatar, width: opts[:size], class: classes, alt: '')
  end

  def author_content_tag(author, opts = {})
    default_opts = { author_class: 'author', tooltip: false, by_username: false }
    opts = default_opts.merge(opts)

    has_tooltip = !opts[:by_username] && opts[:tooltip]

    username = opts[:by_username] ? author.to_reference : author.name
    name_tag_options = { class: [opts[:author_class]] }

    if has_tooltip
      name_tag_options[:title] = author.to_reference
      name_tag_options[:data] = { placement: 'top' }
      name_tag_options[:class] << 'has-tooltip'
    end

    # NOTE: ActionView::Helpers::TagHelper#content_tag HTML escapes username
    content_tag(:span, username, name_tag_options)
  end

  def link_to_member(project, author, opts = {}, &block)
    default_opts = { avatar: true, name: true, title: ":name" }
    opts = default_opts.merge(opts)

    return "(deleted)" unless author

    data_attrs = {
      user_id: author.id,
      username: author.username,
      name: author.name
    }

    inject_classes = ["author-link", opts[:extra_class]]

    if opts[:name]
      inject_classes.concat(["js-user-link", opts[:mobile_classes]])
    else
      inject_classes.append("has-tooltip")
    end

    inject_classes = inject_classes.compact.join(" ")

    author_html = []
    # Build avatar image tag
    author_html << link_to_member_avatar(author, opts) if opts[:avatar]
    # Build name span tag
    author_html << author_content_tag(author, opts) if opts[:name]
    author_html << capture(&block) if block
    author_html = author_html.join.html_safe

    if opts[:name]
      link_to(author_html, user_path(author), class: inject_classes, data: data_attrs).html_safe
    else
      title = opts[:title].sub(":name", sanitize(author.name))
      link_to(author_html, user_path(author), class: inject_classes, title: title, data: { container: 'body' }).html_safe
    end
  end

  def project_title(project)
    namespace_link = build_namespace_breadcrumb_link(project)
    project_link = build_project_breadcrumb_link(project)

    namespace_link = breadcrumb_list_item(namespace_link) unless project.group
    project_link = breadcrumb_list_item project_link

    "#{namespace_link} #{project_link}".html_safe
  end

  def remove_project_message(project)
    _("You are going to delete %{project_full_name}. Deleted projects CANNOT be restored! Are you ABSOLUTELY sure?") %
      { project_full_name: project.full_name }
  end

  def transfer_project_message(project)
    _("You are going to transfer %{project_full_name} to another namespace. Are you ABSOLUTELY sure?") %
      { project_full_name: project.full_name }
  end

  def remove_fork_project_description_message(project)
    source = visible_fork_source(project)

    if source
      msg = _('This will remove the fork relationship between this project and %{fork_source}.') %
        { fork_source: link_to(source.full_name, project_path(source)) }

      msg.html_safe
    else
      _('This will remove the fork relationship between this project and other projects in the fork network.')
    end
  end

  def vue_fork_divergence_data(project, ref)
    source_project = visible_fork_source(project)

    return {} unless source_project

    source_default_branch = source_project.default_branch

    merge_request =
      MergeRequest.opened
        .from_project(project).of_projects(source_project.id).from_source_branches(ref).first

    {
      project_path: project.full_path,
      selected_branch: ref,
      source_name: source_project.full_name,
      source_path: project_path(source_project),
      source_default_branch: source_default_branch,
      can_sync_branch: can_sync_branch?(project, ref).to_s,
      ahead_compare_path: project_compare_path(
        project, from: source_default_branch, to: ref, from_project_id: source_project.id
      ),
      create_mr_path: create_merge_request_path(project, source_project, ref, merge_request),
      view_mr_path: merge_request && project_merge_request_path(source_project, merge_request),
      behind_compare_path: project_compare_path(
        source_project, from: ref, to: source_default_branch, from_project_id: project.id
      )
    }
  end

  def remove_fork_project_warning_message(project)
    _("You are going to remove the fork relationship from %{project_full_name}. Are you ABSOLUTELY sure?") %
      { project_full_name: project.full_name }
  end

  def remove_fork_project_confirm_json(project, remove_form_id)
    {
      remove_form_id: remove_form_id,
      button_text: _('Remove fork relationship'),
      confirm_danger_message: remove_fork_project_warning_message(project),
      phrase: @project.path
    }
  end

  def visible_fork_source(project)
    project.fork_source if project.fork_source && can?(current_user, :read_project, project.fork_source)
  end

  def can_change_visibility_level?(project, current_user)
    can?(current_user, :change_visibility_level, project)
  end

  def can_disable_emails?(project, current_user)
    return false if project.group&.emails_disabled?

    can?(current_user, :set_emails_disabled, project)
  end

  def last_push_event
    current_user&.recent_push(@project)
  end

  def link_to_autodeploy_doc
    link_to _('About auto deploy'), help_page_path('topics/autodevops/stages', anchor: 'auto-deploy'), target: '_blank', rel: 'noopener'
  end

  def autodeploy_flash_notice(branch_name)
    html_escape(_("Branch %{branch_name} was created. To set up auto deploy, choose a GitLab CI Yaml template and commit your changes. %{link_to_autodeploy_doc}")) %
      { branch_name: tag.strong(truncate(sanitize(branch_name))), link_to_autodeploy_doc: link_to_autodeploy_doc }
  end

  def load_pipeline_status(projects)
    Gitlab::Cache::Ci::ProjectPipelineStatus
      .load_in_batch_for_projects(projects)
  end

  def load_catalog_resources(projects)
    ActiveRecord::Associations::Preloader.new(records: projects, associations: :catalog_resource).call
  end

  def last_pipeline_from_status_cache(project)
    if Feature.enabled?(:last_pipeline_from_pipeline_status, project)
      pipeline_status = project.pipeline_status
      return unless pipeline_status.has_status?

      # commits have far more attributes than id, but last_pipeline only requires sha
      return Commit.from_hash({ id: pipeline_status.sha }, project).last_pipeline
    end

    project.last_pipeline
  end

  def show_no_ssh_key_message?
    Gitlab::CurrentSettings.user_show_add_ssh_key_message? &&
      cookies[:hide_no_ssh_message].blank? &&
      !current_user.hide_no_ssh_key &&
      current_user.require_ssh_key?
  end

  def show_no_password_message?
    cookies[:hide_no_password_message].blank? && !current_user.hide_no_password &&
      current_user.require_extra_setup_for_git_auth?
  end

  def show_auto_devops_implicitly_enabled_banner?(project, user)
    return false unless user_can_see_auto_devops_implicitly_enabled_banner?(project, user)

    cookies["hide_auto_devops_implicitly_enabled_banner_#{project.id}".to_sym].blank?
  end

  def show_mobile_devops_project_promo?(project)
    return false unless (project.project_setting.target_platforms & ::ProjectSetting::ALLOWED_TARGET_PLATFORMS).any?

    cookies["hide_mobile_devops_promo_#{project.id}".to_sym].blank?
  end

  def no_password_message
    push_pull_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: help_page_path('topics/git/terminology', anchor: 'pull-and-push') }
    clone_with_https_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: help_page_path('gitlab-basics/start-using-git', anchor: 'clone-with-https') }
    set_password_link_start = '<a href="%{url}">'.html_safe % { url: edit_user_settings_password_path }
    set_up_pat_link_start = '<a href="%{url}">'.html_safe % { url: user_settings_personal_access_tokens_path }

    message = if current_user.require_password_creation_for_git?
                _('Your account is authenticated with SSO or SAML. To %{push_pull_link_start}push and pull%{link_end} over %{protocol} with Git using this account, you must %{set_password_link_start}set a password%{link_end} or %{set_up_pat_link_start}set up a Personal Access Token%{link_end} to use instead of a password. For more information, see %{clone_with_https_link_start}Clone with HTTPS%{link_end}.')
              else
                _('Your account is authenticated with SSO or SAML. To %{push_pull_link_start}push and pull%{link_end} over %{protocol} with Git using this account, you must %{set_up_pat_link_start}set up a Personal Access Token%{link_end} to use instead of a password. For more information, see %{clone_with_https_link_start}Clone with HTTPS%{link_end}.')
              end

    html_escape(message) % {
      push_pull_link_start: push_pull_link_start,
      protocol: gitlab_config.protocol.upcase,
      clone_with_https_link_start: clone_with_https_link_start,
      set_password_link_start: set_password_link_start,
      set_up_pat_link_start: set_up_pat_link_start,
      link_end: '</a>'.html_safe
    }
  end

  # Returns true if any projects are present.
  #
  # If the relation has a LIMIT applied we'll cast the relation to an Array
  # since repeated any? checks would otherwise result in multiple COUNT queries
  # being executed.
  #
  # If no limit is applied we'll just issue a COUNT since the result set could
  # be too large to load into memory.
  def any_projects?(projects)
    return projects.any? if projects.is_a?(Array)

    if projects.limit_value
      projects.to_a.any?
    else
      projects.except(:offset).any?
    end
  end

  def show_projects?(projects, params)
    !!(params[:personal] || params[:name] || params[:language] || any_projects?(projects))
  end

  def push_to_create_project_command(user = current_user)
    repository_url =
      if Gitlab::CurrentSettings.current_application_settings.enabled_git_access_protocol == 'http'
        user_url(user)
      else
        Gitlab.config.gitlab_shell.ssh_path_prefix + user.username
      end

    "git push --set-upstream #{repository_url}/$(git rev-parse --show-toplevel | xargs basename).git $(git rev-parse --abbrev-ref HEAD)"
  end

  def show_xcode_link?(project = @project)
    browser.platform.mac? && project.repository.xcode_project?
  end

  def xcode_uri_to_repo(project = @project)
    "xcode://clone?repo=#{CGI.escape(default_url_to_repo(project))}"
  end

  def explore_projects_tab?
    current_page?(explore_projects_path) ||
      current_page?(trending_explore_projects_path) ||
      current_page?(starred_explore_projects_path)
  end

  def show_count?(disabled: false, compact_mode: false)
    !disabled && !compact_mode
  end

  def error_tracking_setting_project_json
    setting = @project.error_tracking_setting

    return if setting.blank? || setting.project_slug.blank? ||
        setting.organization_slug.blank?

    {
      sentry_project_id: setting.sentry_project_id,
      name: setting.project_name,
      organization_name: setting.organization_name,
      organization_slug: setting.organization_slug,
      slug: setting.project_slug
    }.to_json
  end

  def directory?
    @path.present?
  end

  def external_classification_label_help_message
    default_label = ::Gitlab::CurrentSettings.current_application_settings
                      .external_authorization_service_default_label

    s_(
      "ExternalAuthorizationService|When no classification label is set the "\
        "default label `%{default_label}` will be used."
    ) % { default_label: default_label }
  end

  def can_admin_project_member?(project)
    Ability.allowed?(current_user, :admin_project_member, project) && !membership_locked?
  end

  def project_can_be_shared?
    !membership_locked? || @project.allowed_to_share_with_group?
  end

  def membership_locked?
    false
  end

  def project_license_name(project)
    key = "project:#{project.id}:license_name"

    Gitlab::SafeRequestStore.fetch(key) { project.repository.license&.name }
  rescue GRPC::Unavailable, GRPC::DeadlineExceeded, Gitlab::Git::CommandError => e
    Gitlab::ErrorTracking.track_exception(e)
    Gitlab::SafeRequestStore[key] = nil

    nil
  end

  def show_terraform_banner?(project)
    Feature.enabled?(:show_terraform_banner, type: :ops) && project.repository_languages.with_programming_language('HCL').exists? && project.terraform_states.empty?
  end

  def project_permissions_panel_data(project)
    {
      packagesAvailable: ::Gitlab.config.packages.enabled,
      packagesHelpPath: help_page_path('user/packages/index'),
      currentSettings: project_permissions_settings(project),
      canAddCatalogResource: can_add_catalog_resource?(project),
      canChangeVisibilityLevel: can_change_visibility_level?(project, current_user),
      canDisableEmails: can_disable_emails?(project, current_user),
      allowedVisibilityOptions: project_allowed_visibility_levels(project),
      visibilityHelpPath: help_page_path('user/public_access'),
      registryAvailable: Gitlab.config.registry.enabled,
      registryHelpPath: help_page_path('user/packages/container_registry/index'),
      lfsAvailable: Gitlab.config.lfs.enabled,
      lfsHelpPath: help_page_path('topics/git/lfs/index'),
      lfsObjectsExist: project.lfs_objects.exists?,
      lfsObjectsRemovalHelpPath: help_page_path('topics/git/lfs/index', anchor: 'removing-objects-from-lfs'),
      pagesAvailable: Gitlab.config.pages.enabled,
      pagesAccessControlEnabled: Gitlab.config.pages.access_control,
      pagesAccessControlForced: ::Gitlab::Pages.access_control_is_forced?,
      pagesHelpPath: help_page_path('user/project/pages/introduction', anchor: 'gitlab-pages-access-control'),
      issuesHelpPath: help_page_path('user/project/issues/index'),
      membersPagePath: project_project_members_path(project),
      environmentsHelpPath: help_page_path('ci/environments/index'),
      featureFlagsHelpPath: help_page_path('operations/feature_flags'),
      releasesHelpPath: help_page_path('user/project/releases/index'),
      infrastructureHelpPath: help_page_path('user/infrastructure/index')
    }
  end

  def project_classes(project)
    return "project-highlight-puc" if project.warn_about_potentially_unwanted_characters?

    ""
  end

  # Returns the confirm phrase the user needs to type in order to delete the project
  #
  # Thus the phrase should include the namespace to make it very clear to the
  # user which project is subject to deletion.
  # Relevant issue: https://gitlab.com/gitlab-org/gitlab/-/issues/343591
  def delete_confirm_phrase(project)
    project.path_with_namespace
  end

  def able_to_see_issues?(project, user)
    project.issues_enabled? && can?(user, :read_issue, project)
  end

  def able_to_see_merge_requests?(project, user)
    project.merge_requests_enabled? && can?(user, :read_merge_request, project)
  end

  def able_to_see_forks_count?(project, user)
    project.forking_enabled? && can?(user, :read_code, project)
  end

  def fork_button_data_attributes(project)
    return unless current_user

    if current_user.already_forked?(project) && current_user.forkable_namespaces.size < 2
      user_fork_url = namespace_project_path(current_user, current_user.fork_of(project))
    end

    {
      forks_count: project.forks_count,
      project_full_path: project.full_path,
      project_forks_url: project_forks_path(project),
      user_fork_url: user_fork_url,
      new_fork_url: new_project_fork_path(project),
      can_read_code: can?(current_user, :read_code, project).to_s,
      can_fork_project: can?(current_user, :fork_project, project).to_s,
      can_create_fork: can?(current_user, :create_fork).to_s
    }
  end

  def import_from_bitbucket_message
    configure_oauth_import_message('Bitbucket', help_page_path("integration/bitbucket"))
  end

  def show_inactive_project_deletion_banner?(project)
    return false unless project.present? && project.saved?
    return false unless delete_inactive_projects?

    project.inactive?
  end

  def inactive_project_deletion_date(project)
    Gitlab::InactiveProjectsDeletionWarningTracker.new(project.id).scheduled_deletion_date
  end

  def show_clusters_alert?(project)
    Gitlab.com? && can_admin_associated_clusters?(project)
  end

  def clusters_deprecation_alert_message
    if has_active_license?
      s_('ClusterIntegration|The certificate-based Kubernetes integration is deprecated and will be removed in the future. You should %{linkStart}migrate to the GitLab agent for Kubernetes%{linkEnd}. For more information, see the %{deprecationLinkStart}deprecation epic%{deprecationLinkEnd}, or contact GitLab support.')
    else
      s_('ClusterIntegration|The certificate-based Kubernetes integration is deprecated and will be removed in the future. You should %{linkStart}migrate to the GitLab agent for Kubernetes%{linkEnd}. For more information, see the %{deprecationLinkStart}deprecation epic%{deprecationLinkEnd}.')
    end
  end

  def project_coverage_chart_data_attributes(daily_coverage_options, ref)
    {
      graph_endpoint: "#{daily_coverage_options[:graph_api_path]}?#{daily_coverage_options[:base_params].to_query}",
      graph_start_date: daily_coverage_options[:base_params][:start_date].strftime('%b %d'),
      graph_end_date: daily_coverage_options[:base_params][:end_date].strftime('%b %d'),
      graph_ref: ref.to_s,
      graph_csv_path: "#{daily_coverage_options[:download_path]}?#{daily_coverage_options[:base_params].to_query}"
    }
  end

  def localized_project_human_access(access)
    localized_access_names[access] || Gitlab::Access.human_access(access)
  end

  def badge_count(number)
    format_cached_count(1000, number)
  end

  def remote_mirror_setting_enabled?
    false
  end

  def http_clone_url_to_repo(project)
    project.http_url_to_repo
  end

  def ssh_clone_url_to_repo(project)
    project.ssh_url_to_repo
  end

  def can_view_branch_rules?
    can?(current_user, :maintainer_access, @project)
  end

  def can_push_code?
    current_user&.can?(:push_code, @project)
  end

  def can_admin_associated_clusters?(project)
    can_admin_project_clusters?(project) || can_admin_group_clusters?(project)
  end

  def branch_rules_path
    project_settings_repository_path(@project, anchor: 'js-branch-rules')
  end

  def visibility_level_content(project, css_class: nil, icon_css_class: nil)
    if project.created_and_owned_by_banned_user? && Feature.enabled?(:hide_projects_of_banned_users)
      return hidden_resource_icon(project, css_class: css_class)
    end

    title = visibility_icon_description(project)
    container_class = ['has-tooltip', css_class].compact.join(' ')
    data = { container: 'body', placement: 'top' }

    content_tag(:span, class: container_class, data: data, title: title) do
      visibility_level_icon(project.visibility_level, options: { class: icon_css_class })
    end
  end

  private

  def can_admin_project_clusters?(project)
    project.clusters.any? && can?(current_user, :admin_cluster, project)
  end

  def can_admin_group_clusters?(project)
    project.group && project.group.clusters.any? && can?(current_user, :admin_cluster, project.group)
  end

  def create_merge_request_path(project, source_project, ref, merge_request)
    return if merge_request.present?
    return unless can?(current_user, :create_merge_request_from, project)
    return unless can?(current_user, :create_merge_request_in, source_project)

    create_mr_path(
      from: ref,
      source_project: project,
      to: source_project.default_branch,
      target_project: source_project)
  end

  def can_sync_branch?(project, ref)
    return false unless project.repository.branch_exists?(ref)

    ::Gitlab::UserAccess.new(current_user, container: project).can_push_to_branch?(ref)
  end

  def localized_access_names
    {
      Gitlab::Access::NO_ACCESS => _('No access'),
      Gitlab::Access::MINIMAL_ACCESS => _("Minimal Access"),
      Gitlab::Access::GUEST => _('Guest'),
      Gitlab::Access::REPORTER => _('Reporter'),
      Gitlab::Access::DEVELOPER => _('Developer'),
      Gitlab::Access::MAINTAINER => _('Maintainer'),
      Gitlab::Access::OWNER => _('Owner')
    }
  end

  def configure_oauth_import_message(provider, help_url)
    str = if current_user.can_admin_all_resources?
            'ImportProjects|To enable importing projects from %{provider}, as administrator you need to configure %{link_start}OAuth integration%{link_end}'
          else
            'ImportProjects|To enable importing projects from %{provider}, ask your GitLab administrator to configure %{link_start}OAuth integration%{link_end}'
          end

    link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: help_url }
    s_(str).html_safe % { provider: provider, link_start: link_start, link_end: '</a>'.html_safe }
  end

  def project_lfs_status(project)
    if project.lfs_enabled?
      content_tag(:span, class: 'lfs-enabled') do
        s_('LFSStatus|Enabled')
      end
    else
      content_tag(:span, class: 'lfs-disabled') do
        s_('LFSStatus|Disabled')
      end
    end
  end

  def git_user_name
    if current_user
      current_user.name.gsub('"', '\"')
    else
      _("Your name")
    end
  end

  def git_user_email
    if current_user
      current_user.commit_email_or_default
    else
      "your@email.com"
    end
  end

  def default_url_to_repo(project = @project)
    case default_clone_protocol
    when 'ssh'
      project.ssh_url_to_repo
    else
      project.http_url_to_repo
    end
  end

  def default_clone_label
    _("Copy %{protocol} clone URL") % { protocol: default_clone_protocol.upcase }
  end

  def default_clone_protocol
    if allowed_protocols_present?
      enabled_protocol
    else
      extra_default_clone_protocol
    end
  end

  def extra_default_clone_protocol
    if !current_user || current_user.require_ssh_key?
      gitlab_config.protocol
    else
      'ssh'
    end
  end

  def current_ref
    @ref || @repository.try(:root_ref)
  end

  def project_child_container_class(view_path)
    view_path == "projects/issues/issues" ? "gl-mt-3" : "project-show-#{view_path}"
  end

  def project_issues(project)
    IssuesFinder.new(current_user, project_id: project.id).execute
  end

  def restricted_levels
    return [] if current_user.can_admin_all_resources?

    Gitlab::CurrentSettings.restricted_visibility_levels || []
  end

  def project_permissions_settings(project)
    feature = project.project_feature
    {
      packagesEnabled: !!project.packages_enabled,
      packageRegistryAccessLevel: feature.package_registry_access_level,
      packageRegistryAllowAnyoneToPullOption: ::Gitlab::CurrentSettings.package_registry_allow_anyone_to_pull_option,
      visibilityLevel: project.visibility_level,
      requestAccessEnabled: !!project.request_access_enabled,
      issuesAccessLevel: feature.issues_access_level,
      repositoryAccessLevel: feature.repository_access_level,
      forkingAccessLevel: feature.forking_access_level,
      mergeRequestsAccessLevel: feature.merge_requests_access_level,
      buildsAccessLevel: feature.builds_access_level,
      wikiAccessLevel: feature.wiki_access_level,
      snippetsAccessLevel: feature.snippets_access_level,
      pagesAccessLevel: feature.pages_access_level,
      analyticsAccessLevel: feature.analytics_access_level,
      containerRegistryEnabled: !!project.container_registry_enabled,
      lfsEnabled: !!project.lfs_enabled,
      emailsEnabled: project.emails_enabled?,
      monitorAccessLevel: feature.monitor_access_level,
      showDefaultAwardEmojis: project.show_default_award_emojis?,
      warnAboutPotentiallyUnwantedCharacters: project.warn_about_potentially_unwanted_characters?,
      enforceAuthChecksOnUploads: project.enforce_auth_checks_on_uploads?,
      securityAndComplianceAccessLevel: project.security_and_compliance_access_level,
      containerRegistryAccessLevel: feature.container_registry_access_level,
      environmentsAccessLevel: feature.environments_access_level,
      featureFlagsAccessLevel: feature.feature_flags_access_level,
      releasesAccessLevel: feature.releases_access_level,
      infrastructureAccessLevel: feature.infrastructure_access_level,
      modelExperimentsAccessLevel: feature.model_experiments_access_level,
      modelRegistryAccessLevel: feature.model_registry_access_level
    }
  end

  def project_allowed_visibility_levels(project)
    Gitlab::VisibilityLevel.values.select do |level|
      project.visibility_level_allowed?(level) && !restricted_levels.include?(level)
    end
  end

  def find_file_path(ref_type: nil)
    return unless @project && !@project.empty_repo?
    return unless can?(current_user, :read_code, @project)

    ref = @ref || @project.repository.root_ref

    project_find_file_path(@project, ref, ref_type: ref_type)
  end

  def can_show_last_commit_in_list?(project)
    can?(current_user, :read_cross_project) &&
      can?(current_user, :read_commit_status, project) &&
      project.commit
  end

  def pages_https_only_disabled?
    !@project.pages_domains.all?(&:https?)
  end

  def pages_https_only_title
    return unless pages_https_only_disabled?

    "You must enable HTTPS for all your domains first"
  end

  def filter_starrer_path(options = {})
    options = params.slice(:sort).merge(options).permit!
    "#{request.path}?#{options.to_param}"
  end

  def sidebar_operations_paths
    %w[
      environments
      clusters
      cluster_agents
      functions
      error_tracking
      alert_management
      incidents
      incident_management
      user
      gcp
      logs
      product_analytics
      metrics_dashboard
      feature_flags
      terraform
    ]
  end

  def user_can_see_auto_devops_implicitly_enabled_banner?(project, user)
    Ability.allowed?(user, :admin_project, project) &&
      project.has_auto_devops_implicitly_enabled? &&
      project.builds_enabled? &&
      !project.repository.gitlab_ci_yml
  end

  def show_visibility_confirm_modal?(project)
    project.visibility_level > Gitlab::VisibilityLevel::PRIVATE && project.forks_count > 0
  end

  def confirm_reduce_visibility_message(project)
    strong_start = "<strong>".html_safe
    strong_end = "</strong>".html_safe
    message = _("You're about to reduce the visibility of the project %{strong_start}%{project_name}%{strong_end}.")

    if project.group
      message = _("You're about to reduce the visibility of the project %{strong_start}%{project_name}%{strong_end} in %{strong_start}%{group_name}%{strong_end}.")
    end

    html_escape(message) % { strong_start: strong_start, strong_end: strong_end, project_name: project.name, group_name: project.group ? project.group.name : nil }
  end

  def visibility_confirm_modal_data(project, target_form_id = nil)
    {
      target_form_id: target_form_id,
      button_testid: 'reduce-project-visibility-button',
      confirm_button_text: _('Reduce project visibility'),
      confirm_danger_message: confirm_reduce_visibility_message(project),
      phrase: project.full_path,
      additional_information: _('Note: current forks will keep their visibility level.'),
      html_confirmation_message: true.to_s,
      show_visibility_confirm_modal: show_visibility_confirm_modal?(project).to_s
    }
  end

  def build_project_breadcrumb_link(project)
    project_name = simple_sanitize(project.name)

    push_to_schema_breadcrumb(project_name, project_path(project))

    link_to project_path(project) do
      icon = render Pajamas::AvatarComponent.new(project, alt: project.name, size: 16, class: 'avatar-tile') if project.avatar_url && !Rails.env.test?
      [icon, content_tag("span", project_name, class: "js-breadcrumb-item-text")].join.html_safe
    end
  end

  def build_namespace_breadcrumb_link(project)
    if project.group
      group_title(project.group, nil, nil)
    else
      owner = project.namespace.owner
      name = simple_sanitize(owner.name)
      url = user_path(owner)

      push_to_schema_breadcrumb(name, url)
      link_to(name, url)
    end
  end

  def delete_inactive_projects?
    strong_memoize(:delete_inactive_projects_setting) do
      ::Gitlab::CurrentSettings.delete_inactive_projects?
    end
  end
end

ProjectsHelper.prepend_mod_with('ProjectsHelper')

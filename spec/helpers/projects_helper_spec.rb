# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectsHelper, feature_category: :source_code_management do
  include ProjectForksHelper
  include AfterNextHelpers

  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be_with_refind(:project_with_repo) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
    helper.instance_variable_set(:@project, project)
  end

  describe '#project_incident_management_setting' do
    context 'when incident_management_setting exists' do
      let(:project_incident_management_setting) do
        create(:project_incident_management_setting, project: project)
      end

      it 'return project_incident_management_setting' do
        expect(helper.project_incident_management_setting).to(
          eq(project_incident_management_setting)
        )
      end
    end

    context 'when incident_management_setting does not exist' do
      it 'builds incident_management_setting' do
        setting = helper.project_incident_management_setting

        expect(setting).not_to be_persisted
        expect(setting.create_issue).to be_falsey
        expect(setting.send_email).to be_falsey
        expect(setting.issue_template_key).to be_nil
      end
    end
  end

  describe '#error_tracking_setting_project_json' do
    context 'error tracking setting does not exist' do
      it 'returns nil' do
        expect(helper.error_tracking_setting_project_json).to be_nil
      end
    end

    context 'error tracking setting exists' do
      let_it_be(:error_tracking_setting) { create(:project_error_tracking_setting, project: project) }

      context 'api_url present' do
        let(:json) do
          {
            sentry_project_id: error_tracking_setting.sentry_project_id,
            name: error_tracking_setting.project_name,
            organization_name: error_tracking_setting.organization_name,
            organization_slug: error_tracking_setting.organization_slug,
            slug: error_tracking_setting.project_slug
          }.to_json
        end

        it 'returns error tracking json' do
          expect(helper.error_tracking_setting_project_json).to eq(json)
        end
      end

      context 'api_url not present' do
        it 'returns nil' do
          project.error_tracking_setting.api_url = nil
          project.error_tracking_setting.enabled = false

          expect(helper.error_tracking_setting_project_json).to be_nil
        end
      end
    end
  end

  describe "can_change_visibility_level?" do
    let_it_be(:user) { create(:project_member, :reporter, user: create(:user), project: project).user }

    let(:forked_project) { fork_project(project, user) }

    it "returns false if there are no appropriate permissions" do
      allow(helper).to receive(:can?) { false }

      expect(helper.can_change_visibility_level?(project, user)).to be_falsey
    end

    it "returns true if there are permissions" do
      allow(helper).to receive(:can?) { true }

      expect(helper.can_change_visibility_level?(project, user)).to be_truthy
    end
  end

  describe '#can_disable_emails?' do
    let_it_be(:user) { create(:project_member, :maintainer, user: create(:user), project: project).user }

    it 'returns true for the project owner' do
      allow(helper).to receive(:can?).with(project.owner, :set_emails_disabled, project) { true }

      expect(helper.can_disable_emails?(project, project.owner)).to be_truthy
    end

    it 'returns false for anyone else' do
      allow(helper).to receive(:can?).with(user, :set_emails_disabled, project) { false }

      expect(helper.can_disable_emails?(project, user)).to be_falsey
    end

    it 'returns false if group emails disabled' do
      project = create(:project, group: create(:group))
      allow(project.group).to receive(:emails_disabled?).and_return(true)

      expect(helper.can_disable_emails?(project, project.owner)).to be_falsey
    end
  end

  describe '#load_pipeline_status' do
    it 'loads the pipeline status in batch' do
      helper.load_pipeline_status([project])
      # Skip lazy loading of the `pipeline_status` attribute
      pipeline_status = project.instance_variable_get(:@pipeline_status)

      expect(pipeline_status).to be_a(Gitlab::Cache::Ci::ProjectPipelineStatus)
    end
  end

  describe '#load_catalog_resources' do
    before_all do
      create_list(:project, 2)
    end

    let_it_be(:projects) { Project.all.to_a }

    it 'does not execute a database query when project.catalog_resource is accessed' do
      helper.load_catalog_resources(projects)

      queries = ActiveRecord::QueryRecorder.new do
        projects.each(&:catalog_resource)
      end

      expect(queries).not_to exceed_query_limit(0)
    end
  end

  describe '#last_pipeline_from_status_cache' do
    before do
      # clear cross-example caches
      project_with_repo.pipeline_status.delete_from_cache
      project_with_repo.instance_variable_set(:@pipeline_status, nil)
    end

    context 'without a pipeline' do
      it 'returns nil', :aggregate_failures do
        expect(::Gitlab::GitalyClient).to receive(:call).at_least(:once).and_call_original
        actual_pipeline = last_pipeline_from_status_cache(project_with_repo)
        expect(actual_pipeline).to be_nil
      end

      context 'when pipeline_status is loaded' do
        before do
          project_with_repo.pipeline_status # this loads the status
        end

        it 'returns nil without calling gitaly when there is no pipeline', :aggregate_failures do
          expect(::Gitlab::GitalyClient).not_to receive(:call)
          actual_pipeline = last_pipeline_from_status_cache(project_with_repo)
          expect(actual_pipeline).to be_nil
        end
      end

      context 'when FF load_last_pipeline_from_pipeline_status is disabled' do
        before do
          stub_feature_flags(last_pipeline_from_pipeline_status: false)
        end

        it 'returns nil', :aggregate_failures do
          expect(project_with_repo).not_to receive(:pipeline_status)
          actual_pipeline = last_pipeline_from_status_cache(project_with_repo)
          expect(actual_pipeline).to be_nil
        end
      end
    end

    context 'with a pipeline' do
      let_it_be(:pipeline) { create(:ci_pipeline, project: project_with_repo) }

      it 'returns the latest pipeline', :aggregate_failures do
        expect(::Gitlab::GitalyClient).to receive(:call).at_least(:once).and_call_original
        actual_pipeline = last_pipeline_from_status_cache(project_with_repo)
        expect(actual_pipeline).to eq pipeline
      end

      context 'when pipeline_status is loaded' do
        before do
          project_with_repo.pipeline_status # this loads the status
        end

        it 'returns the latest pipeline without calling gitaly' do
          expect(::Gitlab::GitalyClient).not_to receive(:call)
          actual_pipeline = last_pipeline_from_status_cache(project_with_repo)
          expect(actual_pipeline).to eq pipeline
        end

        context 'when FF load_last_pipeline_from_pipeline_status is disabled' do
          before do
            stub_feature_flags(last_pipeline_from_pipeline_status: false)
          end

          it 'returns the latest pipeline', :aggregate_failures do
            expect(project_with_repo).not_to receive(:pipeline_status)
            actual_pipeline = last_pipeline_from_status_cache(project_with_repo)
            expect(actual_pipeline).to eq pipeline
          end
        end
      end
    end
  end

  describe '#show_no_ssh_key_message?' do
    context 'user has no keys' do
      it 'returns true' do
        expect(helper.show_no_ssh_key_message?).to be_truthy
      end
    end

    context 'user has an ssh key' do
      it 'returns false' do
        create(:personal_key, user: user)

        expect(helper.show_no_ssh_key_message?).to be_falsey
      end
    end
  end

  describe '#show_no_password_message?' do
    context 'user has password set' do
      it 'returns false' do
        expect(helper.show_no_password_message?).to be_falsey
      end
    end

    context 'user has hidden the message' do
      it 'returns false' do
        allow(helper).to receive(:cookies).and_return(hide_no_password_message: true)

        expect(helper.show_no_password_message?).to be_falsey
      end
    end

    context 'user requires a password for Git' do
      it 'returns true' do
        allow(user).to receive(:require_password_creation_for_git?).and_return(true)

        expect(helper.show_no_password_message?).to be_truthy
      end
    end

    context 'user requires a personal access token for Git' do
      it 'returns true' do
        allow(user).to receive(:require_password_creation_for_git?).and_return(false)
        allow(user).to receive(:require_personal_access_token_creation_for_git_auth?).and_return(true)

        expect(helper.show_no_password_message?).to be_truthy
      end
    end
  end

  describe '#no_password_message' do
    let(:user) { create(:user, password_automatically_set: true) }

    context 'password authentication is enabled for Git' do
      it 'returns message prompting user to set password or set up a PAT' do
        stub_application_setting(password_authentication_enabled_for_git?: true)

        expect(helper.no_password_message).to eq('Your account is authenticated with SSO or SAML. To <a href="/help/topics/git/terminology#pull-and-push" target="_blank" rel="noopener noreferrer">push and pull</a> over HTTP with Git using this account, you must <a href="/-/user_settings/password/edit">set a password</a> or <a href="/-/user_settings/personal_access_tokens">set up a Personal Access Token</a> to use instead of a password. For more information, see <a href="/help/gitlab-basics/start-using-git#clone-with-https" target="_blank" rel="noopener noreferrer">Clone with HTTPS</a>.')
      end
    end

    context 'password authentication is disabled for Git' do
      it 'returns message prompting user to set up a PAT' do
        stub_application_setting(password_authentication_enabled_for_git?: false)

        expect(helper.no_password_message).to eq('Your account is authenticated with SSO or SAML. To <a href="/help/topics/git/terminology#pull-and-push" target="_blank" rel="noopener noreferrer">push and pull</a> over HTTP with Git using this account, you must <a href="/-/user_settings/personal_access_tokens">set up a Personal Access Token</a> to use instead of a password. For more information, see <a href="/help/gitlab-basics/start-using-git#clone-with-https" target="_blank" rel="noopener noreferrer">Clone with HTTPS</a>.')
      end
    end
  end

  describe '#link_to_project' do
    let(:group)   { create(:group, name: 'group name with space') }
    let(:project) { create(:project, group: group, name: 'project name with space') }

    subject { link_to_project(project) }

    it 'returns an HTML link to the project' do
      expect(subject).to match(%r{/#{group.full_path}/#{project.path}})
      expect(subject).to include('group name with space /')
      expect(subject).to include('project name with space')
    end
  end

  describe '#link_to_member_avatar' do
    let(:user) { build_stubbed(:user) }
    let(:expected) { double }

    before do
      expect(helper).to receive(:avatar_icon_for_user).with(user, 16).and_return(expected)
    end

    it 'returns image tag for member avatar' do
      expect(helper).to receive(:image_tag).with(expected, { width: 16, class: %w[avatar avatar-inline s16], alt: "" })

      helper.link_to_member_avatar(user)
    end

    it 'returns image tag with avatar class' do
      expect(helper).to receive(:image_tag).with(expected, { width: 16, class: %w[avatar avatar-inline s16 any-avatar-class], alt: "" })

      helper.link_to_member_avatar(user, avatar_class: "any-avatar-class")
    end
  end

  describe '#link_to_member' do
    let(:group)   { build_stubbed(:group) }
    let(:project) { build_stubbed(:project, group: group) }
    let(:user)    { build_stubbed(:user, name: '<h1>Administrator</h1>') }

    describe 'using the default options' do
      it 'returns an HTML link to the user' do
        link = helper.link_to_member(project, user)

        expect(link).to match(%r{/#{user.username}})
      end

      it 'HTML escapes the name of the user' do
        link = helper.link_to_member(project, user)

        expect(link).to include(ERB::Util.html_escape(user.name))
        expect(link).not_to include(user.name)
      end
    end

    context 'when user is nil' do
      it 'returns "(deleted)"' do
        link = helper.link_to_member(project, nil)

        expect(link).to eq("(deleted)")
      end
    end
  end

  describe 'default_clone_protocol' do
    let(:user) { nil }

    context 'when user is not logged in and gitlab protocol is HTTP' do
      it 'returns HTTP' do
        expect(helper.send(:default_clone_protocol)).to eq('http')
      end
    end

    context 'when user is not logged in and gitlab protocol is HTTPS' do
      it 'returns HTTPS' do
        stub_config_setting(protocol: 'https')

        expect(helper.send(:default_clone_protocol)).to eq('https')
      end
    end
  end

  describe '#last_push_event' do
    let(:user) { double(:user, fork_of: nil) }
    let(:project) { double(:project, id: 1) }

    context 'when there is no current_user' do
      let(:user) { nil }

      it 'returns nil' do
        expect(helper.last_push_event).to eq(nil)
      end
    end

    it 'returns recent push on the current project' do
      event = double(:event)
      expect(user).to receive(:recent_push).with(project).and_return(event)

      expect(helper.last_push_event).to eq(event)
    end
  end

  describe '#show_projects' do
    let(:projects) do
      Project.all
    end

    it 'returns true when there are projects' do
      expect(helper.show_projects?(projects, {})).to eq(true)
    end

    it 'returns true when there are no projects but a name is given' do
      expect(helper.show_projects?(Project.none, name: 'foo')).to eq(true)
    end

    it 'returns true when there are no projects but personal is present' do
      expect(helper.show_projects?(Project.none, personal: 'true')).to eq(true)
    end

    it 'returns false when there are no projects and there is no name' do
      expect(helper.show_projects?(Project.none, {})).to eq(false)
    end
  end

  describe '#push_to_create_project_command' do
    let(:user) { build_stubbed(:user, username: 'john') }

    it 'returns the command to push to create project over HTTP' do
      allow(Gitlab::CurrentSettings.current_application_settings).to receive(:enabled_git_access_protocol) { 'http' }

      expect(helper.push_to_create_project_command(user)).to eq('git push --set-upstream http://test.host/john/$(git rev-parse --show-toplevel | xargs basename).git $(git rev-parse --abbrev-ref HEAD)')
    end

    it 'returns the command to push to create project over SSH' do
      allow(Gitlab::CurrentSettings.current_application_settings).to receive(:enabled_git_access_protocol) { 'ssh' }

      expect(helper.push_to_create_project_command(user)).to eq("git push --set-upstream #{Gitlab.config.gitlab.user}@localhost:john/$(git rev-parse --show-toplevel | xargs basename).git $(git rev-parse --abbrev-ref HEAD)")
    end
  end

  describe '#any_projects?' do
    it 'returns true when projects will be returned' do
      expect(helper.any_projects?(Project.all)).to eq(true)
    end

    it 'returns false when no projects will be returned' do
      expect(helper.any_projects?(Project.none)).to eq(false)
    end

    it 'returns true when using a non-empty Array' do
      expect(helper.any_projects?([project])).to eq(true)
    end

    it 'returns false when using an empty Array' do
      expect(helper.any_projects?([])).to eq(false)
    end

    it 'only executes a single query when a LIMIT is applied' do
      relation = Project.limit(1)
      recorder = ActiveRecord::QueryRecorder.new do
        2.times do
          helper.any_projects?(relation)
        end
      end

      expect(recorder.count).to eq(1)
    end
  end

  describe '#git_user_name' do
    let(:user) { build_stubbed(:user, name: 'John "A" Doe53') }

    it 'parses quotes in name' do
      expect(helper.send(:git_user_name)).to eq('John \"A\" Doe53')
    end
  end

  describe '#git_user_email' do
    context 'not logged-in' do
      let(:user) { nil }

      it 'returns your@email.com' do
        expect(helper.send(:git_user_email)).to eq('your@email.com')
      end
    end

    context 'user logged in' do
      context 'user has no configured commit email' do
        it 'returns the primary email' do
          expect(helper.send(:git_user_email)).to eq(user.email)
        end
      end

      context 'user has a configured commit email' do
        before do
          confirmed_email = create(:email, :confirmed, user: user)
          user.update!(commit_email: confirmed_email.email)
        end

        it 'returns the commit email' do
          expect(helper.send(:git_user_email)).to eq(user.commit_email)
        end
      end
    end
  end

  describe 'show_xcode_link' do
    let(:mac_ua) { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.139 Safari/537.36' }
    let(:ios_ua) { 'Mozilla/5.0 (iPad; CPU OS 5_1_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9B206 Safari/7534.48.3' }

    context 'when the repository is xcode compatible' do
      before do
        allow(project.repository).to receive(:xcode_project?).and_return(true)
      end

      it 'returns false if the visitor is not using macos' do
        allow(helper).to receive(:browser).and_return(Browser.new(ios_ua))

        expect(helper.show_xcode_link?(project)).to eq(false)
      end

      it 'returns true if the visitor is using macos' do
        allow(helper).to receive(:browser).and_return(Browser.new(mac_ua))

        expect(helper.show_xcode_link?(project)).to eq(true)
      end
    end

    context 'when the repository is not xcode compatible' do
      before do
        allow(project.repository).to receive(:xcode_project?).and_return(false)
      end

      it 'returns false if the visitor is not using macos' do
        allow(helper).to receive(:browser).and_return(Browser.new(ios_ua))

        expect(helper.show_xcode_link?(project)).to eq(false)
      end

      it 'returns false if the visitor is using macos' do
        allow(helper).to receive(:browser).and_return(Browser.new(mac_ua))

        expect(helper.show_xcode_link?(project)).to eq(false)
      end
    end
  end

  describe '#explore_projects_tab?' do
    subject { helper.explore_projects_tab? }

    it 'returns true when on the "All" tab under "Explore projects"' do
      allow(@request).to receive(:path) { explore_projects_path }

      expect(subject).to be_truthy
    end

    it 'returns true when on the "Trending" tab under "Explore projects"' do
      allow(@request).to receive(:path) { trending_explore_projects_path }

      expect(subject).to be_truthy
    end

    it 'returns true when on the "Starred" tab under "Explore projects"' do
      allow(@request).to receive(:path) { starred_explore_projects_path }

      expect(subject).to be_truthy
    end

    it 'returns false when on the "Your projects" tab' do
      allow(@request).to receive(:path) { dashboard_projects_path }

      expect(subject).to be_falsey
    end
  end

  describe '#show_count?' do
    context 'enabled flag' do
      it 'returns true if compact mode is disabled' do
        expect(helper.show_count?).to be_truthy
      end

      it 'returns false if compact mode is enabled' do
        expect(helper.show_count?(compact_mode: true)).to be_falsey
      end
    end

    context 'disabled flag' do
      it 'returns false if disabled flag is true' do
        expect(helper.show_count?(disabled: true)).to be_falsey
      end

      it 'returns true if disabled flag is false' do
        expect(helper).to be_show_count
      end
    end
  end

  describe '#show_auto_devops_implicitly_enabled_banner?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be_with_reload(:project_with_auto_devops) { create(:project, :repository, :auto_devops) }

    let(:feature_visibilities) do
      {
        enabled: ProjectFeature::ENABLED,
        disabled: ProjectFeature::DISABLED
      }
    end

    where(:global_setting, :project_setting, :builds_visibility, :gitlab_ci_yml, :user_access, :result) do
      # With ADO implicitly enabled scenarios
      true | nil | :disabled | true  | :developer  | false
      true | nil | :disabled | true  | :maintainer | false
      true | nil | :disabled | true  | :owner      | false

      true | nil | :disabled | false | :developer  | false
      true | nil | :disabled | false | :maintainer | false
      true | nil | :disabled | false | :owner      | false

      true | nil | :enabled  | true  | :developer  | false
      true | nil | :enabled  | true  | :maintainer | false
      true | nil | :enabled  | true  | :owner      | false

      true | nil | :enabled  | false | :developer  | false
      true | nil | :enabled  | false | :maintainer | true
      true | nil | :enabled  | false | :owner      | true

      # With ADO enabled scenarios
      true | true | :disabled | true  | :developer  | false
      true | true | :disabled | true  | :maintainer | false
      true | true | :disabled | true  | :owner      | false

      true | true | :disabled | false | :developer  | false
      true | true | :disabled | false | :maintainer | false
      true | true | :disabled | false | :owner      | false

      true | true | :enabled  | true  | :developer  | false
      true | true | :enabled  | true  | :maintainer | false
      true | true | :enabled  | true  | :owner      | false

      true | true | :enabled  | false | :developer  | false
      true | true | :enabled  | false | :maintainer | false
      true | true | :enabled  | false | :owner      | false

      # With ADO disabled scenarios
      true | false | :disabled | true  | :developer  | false
      true | false | :disabled | true  | :maintainer | false
      true | false | :disabled | true  | :owner      | false

      true | false | :disabled | false | :developer  | false
      true | false | :disabled | false | :maintainer | false
      true | false | :disabled | false | :owner      | false

      true | false | :enabled  | true  | :developer  | false
      true | false | :enabled  | true  | :maintainer | false
      true | false | :enabled  | true  | :owner      | false

      true | false | :enabled  | false | :developer  | false
      true | false | :enabled  | false | :maintainer | false
      true | false | :enabled  | false | :owner      | false
    end

    def grant_user_access(project, user, access)
      case access
      when :developer, :maintainer
        project.add_member(user, access)
      when :owner
        project.namespace.update!(owner: user)
      end
    end

    with_them do
      let(:project) do
        if project_setting.nil?
          project_with_repo
        else
          project_with_auto_devops
        end
      end

      before do
        stub_application_setting(auto_devops_enabled: global_setting)

        allow_any_instance_of(Repository).to receive(:gitlab_ci_yml).and_return(gitlab_ci_yml)

        grant_user_access(project, user, user_access)
        project.project_feature.update_attribute(:builds_access_level, feature_visibilities[builds_visibility])
        project.auto_devops.update_attribute(:enabled, project_setting) unless project_setting.nil?
      end

      subject { helper.show_auto_devops_implicitly_enabled_banner?(project, user) }

      it { is_expected.to eq(result) }
    end
  end

  describe '#show_mobile_devops_project_promo?' do
    using RSpec::Parameterized::TableSyntax

    where(:hide_cookie, :mobile_target_platform, :result) do
      false | true | true
      false | false | false
      true | false | false
      true | true | false
    end

    with_them do
      before do
        allow(Gitlab).to receive(:com?) { gitlab_com }
        project.project_setting.target_platforms << 'ios' if mobile_target_platform
        helper.request.cookies["hide_mobile_devops_promo_#{project.id}"] = true if hide_cookie
      end

      it 'resolves if mobile devops promo banner should be displayed' do
        expect(helper.show_mobile_devops_project_promo?(project)).to eq result
      end
    end
  end

  describe '#can_admin_project_member?' do
    context 'when user is project owner' do
      let(:user) { project.owner }

      it 'returns true for owner of project' do
        expect(helper.can_admin_project_member?(project)).to eq true
      end
    end

    context 'when user is not a project owner' do
      using RSpec::Parameterized::TableSyntax

      where(:user_project_role, :can_admin) do
        :maintainer | true
        :developer | false
        :reporter | false
        :guest | false
      end

      with_them do
        before do
          project.add_role(user, user_project_role)
        end

        it 'resolves if the user can import members' do
          expect(helper.can_admin_project_member?(project)).to eq can_admin
        end
      end
    end
  end

  describe '#project_license_name(project)', :request_store do
    let_it_be(:repository) { project.repository }

    subject { project_license_name(project) }

    def license_name
      project_license_name(project)
    end

    context 'gitaly is working appropriately' do
      let(:license) { ::Gitlab::Git::DeclaredLicense.new(key: 'mit', name: 'MIT License') }

      before do
        expect(repository).to receive(:license).and_return(license)
      end

      it 'returns the license name' do
        expect(subject).to eq(license.name)
      end

      it 'memoizes the value' do
        expect do
          2.times { expect(license_name).to eq(license.name) }
        end.to change { Gitlab::GitalyClient.get_request_count }.by_at_most(1)
      end
    end

    context 'gitaly is unreachable' do
      shared_examples 'returns nil and tracks exception' do
        it { is_expected.to be_nil }

        it 'tracks the exception' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            an_instance_of(exception)
          )

          subject
        end

        it 'memoizes the nil value' do
          expect do
            2.times { expect(license_name).to be_nil }
          end.to change { Gitlab::GitalyClient.get_request_count }.by_at_most(1)
        end
      end

      before do
        expect(repository).to receive(:license).and_raise(exception)
      end

      context "Gitlab::Git::CommandError" do
        let(:exception) { Gitlab::Git::CommandError }

        it_behaves_like 'returns nil and tracks exception'
      end

      context "GRPC::Unavailable" do
        let(:exception) { GRPC::Unavailable }

        it_behaves_like 'returns nil and tracks exception'
      end

      context "GRPC::DeadlineExceeded" do
        let(:exception) { GRPC::DeadlineExceeded }

        it_behaves_like 'returns nil and tracks exception'
      end
    end
  end

  describe '#show_terraform_banner?' do
    let_it_be(:ruby) { create(:programming_language, name: 'Ruby') }
    let_it_be(:hcl) { create(:programming_language, name: 'HCL') }

    subject { helper.show_terraform_banner?(project) }

    before do
      create(:repository_language, project: project, programming_language: language, share: 1)
    end

    context 'the project does not contain terraform files' do
      let(:language) { ruby }

      it { is_expected.to be_falsey }
    end

    context 'the project contains terraform files' do
      let(:language) { hcl }

      it { is_expected.to be_truthy }

      context 'the project already has a terraform state' do
        before do
          create(:terraform_state, project: project)
        end

        it { is_expected.to be_falsey }
      end

      context 'the :show_terraform_banner feature flag is disabled' do
        before do
          stub_feature_flags(show_terraform_banner: false)
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#project_title' do
    subject { helper.project_title(project) }

    it 'enqueues the elements in the breadcrumb schema list' do
      expect(helper).to receive(:push_to_schema_breadcrumb).with(project.namespace.name, user_path(project.owner))
      expect(helper).to receive(:push_to_schema_breadcrumb).with(project.name, project_path(project))

      subject
    end

    context 'with malicious owner name' do
      before do
        allow_any_instance_of(User).to receive(:name).and_return('a<a class="fixed-top" href=/api/v4')
      end

      it 'escapes the malicious owner name' do
        expect(subject).not_to include('<a class="fixed-top" href="/api/v4"></a>')
      end
    end
  end

  describe '#project_permissions_panel_data' do
    subject { helper.project_permissions_panel_data(project) }

    before do
      allow(helper).to receive(:can?) { true }
    end

    it 'includes project_permissions_settings' do
      settings = subject.dig(:currentSettings)

      expect(settings).to include(
        packagesEnabled: !!project.packages_enabled,
        packageRegistryAllowAnyoneToPullOption: ::Gitlab::CurrentSettings.package_registry_allow_anyone_to_pull_option,
        visibilityLevel: project.visibility_level,
        requestAccessEnabled: !!project.request_access_enabled,
        issuesAccessLevel: project.project_feature.issues_access_level,
        repositoryAccessLevel: project.project_feature.repository_access_level,
        forkingAccessLevel: project.project_feature.forking_access_level,
        mergeRequestsAccessLevel: project.project_feature.merge_requests_access_level,
        buildsAccessLevel: project.project_feature.builds_access_level,
        wikiAccessLevel: project.project_feature.wiki_access_level,
        snippetsAccessLevel: project.project_feature.snippets_access_level,
        pagesAccessLevel: project.project_feature.pages_access_level,
        analyticsAccessLevel: project.project_feature.analytics_access_level,
        containerRegistryEnabled: !!project.container_registry_enabled,
        lfsEnabled: !!project.lfs_enabled,
        emailsEnabled: project.emails_enabled?,
        showDefaultAwardEmojis: project.show_default_award_emojis?,
        securityAndComplianceAccessLevel: project.security_and_compliance_access_level,
        containerRegistryAccessLevel: project.project_feature.container_registry_access_level,
        environmentsAccessLevel: project.project_feature.environments_access_level,
        featureFlagsAccessLevel: project.project_feature.feature_flags_access_level,
        releasesAccessLevel: project.project_feature.releases_access_level,
        infrastructureAccessLevel: project.project_feature.infrastructure_access_level,
        modelExperimentsAccessLevel: project.project_feature.model_experiments_access_level,
        modelRegistryAccessLevel: project.project_feature.model_registry_access_level
      )
    end

    it 'includes membersPagePath' do
      expect(subject).to include(membersPagePath: project_project_members_path(project))
    end

    it 'includes canAddCatalogResource' do
      allow(helper).to receive(:can?) { false }

      expect(subject).to include(canAddCatalogResource: false)
    end
  end

  describe '#project_classes' do
    subject { helper.project_classes(project) }

    it { is_expected.to be_a(String) }

    context 'PUC highlighting enabled' do
      before do
        project.warn_about_potentially_unwanted_characters = true
      end

      it { is_expected.to include('project-highlight-puc') }
    end

    context 'PUC highlighting disabled' do
      before do
        project.warn_about_potentially_unwanted_characters = false
      end

      it { is_expected.not_to include('project-highlight-puc') }
    end
  end

  describe "#delete_confirm_phrase" do
    subject { helper.delete_confirm_phrase(project) }

    it 'includes the project path with namespace' do
      expect(subject).to eq(project.path_with_namespace)
    end
  end

  context 'fork security helpers' do
    using RSpec::Parameterized::TableSyntax

    describe "#able_to_see_merge_requests?" do
      subject { helper.able_to_see_merge_requests?(project, user) }

      where(:can_read_merge_request, :merge_requests_enabled, :expected) do
        false | false | false
        true | false | false
        false | true | false
        true | true | true
      end

      with_them do
        before do
          allow(project).to receive(:merge_requests_enabled?).and_return(merge_requests_enabled)
          allow(helper).to receive(:can?).with(user, :read_merge_request, project).and_return(can_read_merge_request)
        end

        it 'returns the correct response' do
          expect(subject).to eq(expected)
        end
      end
    end

    describe "#able_to_see_issues?" do
      subject { helper.able_to_see_issues?(project, user) }

      where(:can_read_issues, :issues_enabled, :expected) do
        false | false | false
        true | false | false
        false | true | false
        true | true | true
      end

      with_them do
        before do
          allow(project).to receive(:issues_enabled?).and_return(issues_enabled)
          allow(helper).to receive(:can?).with(user, :read_issue, project).and_return(can_read_issues)
        end

        it 'returns the correct response' do
          expect(subject).to eq(expected)
        end
      end
    end

    describe '#able_to_see_forks_count?' do
      subject { helper.able_to_see_forks_count?(project, user) }

      where(:can_read_code, :forking_enabled, :expected) do
        false | false | false
        true  | false | false
        false | true  | false
        true  | true  | true
      end

      with_them do
        before do
          allow(project).to receive(:forking_enabled?).and_return(forking_enabled)
          allow(helper).to receive(:can?).with(user, :read_code, project).and_return(can_read_code)
        end

        it 'returns the correct response' do
          expect(subject).to eq(expected)
        end
      end
    end
  end

  describe '#fork_button_data_attributes' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:project) { create(:project, :repository, :public) }

    project_path = '/project/path'
    project_forks_path = '/project/forks'
    project_new_fork_path = '/project/new/fork'
    user_fork_url = '/user/fork'

    common_data_attributes = {
      forks_count: 4,
      project_full_path: project_path,
      project_forks_url: project_forks_path,
      can_create_fork: "true",
      can_fork_project: "true",
      can_read_code: "true",
      new_fork_url: project_new_fork_path
    }

    data_attributes_with_user_fork_url = common_data_attributes.merge({ user_fork_url: user_fork_url })
    data_attributes_without_user_fork_url = common_data_attributes.merge({ user_fork_url: nil })

    subject { helper.fork_button_data_attributes(project) }

    # The stubs for the forkable namespaces seem not to make sense (they're just numbers),
    # but they're set up that way because we don't really care about what the array contains, only about its length
    where(:has_user, :project_already_forked, :forkable_namespaces, :expected) do
      false | false | []     | nil
      true  | false | [0]    | data_attributes_without_user_fork_url
      true  | false | [0, 1] | data_attributes_without_user_fork_url
      true  | true  | [0]    | data_attributes_with_user_fork_url
      true  | true  | [0, 1] | data_attributes_without_user_fork_url
    end

    with_them do
      before do
        current_user = user if has_user

        allow(helper).to receive(:current_user).and_return(current_user)
        allow(user).to receive(:can?).and_call_original
        allow(user).to receive(:can?).with(:fork_project, project).and_return(true)
        allow(user).to receive(:can?).with(:create_fork).and_return(true)
        allow(user).to receive(:can?).with(:create_projects, anything).and_return(true)
        allow(user).to receive(:already_forked?).with(project).and_return(project_already_forked)
        allow(user).to receive(:forkable_namespaces).and_return(forkable_namespaces)

        allow(project).to receive(:forks_count).and_return(4)
        allow(project).to receive(:full_path).and_return(project_path)

        user_fork_path = user_fork_url if project_already_forked
        allow(helper).to receive(:namespace_project_path).with(user, anything).and_return(user_fork_path)
        allow(helper).to receive(:new_project_fork_path).with(project).and_return(project_new_fork_path)
        allow(helper).to receive(:project_forks_path).with(project).and_return(project_forks_path)
      end

      it { is_expected.to eq(expected) }
    end
  end

  shared_examples 'configure import method modal' do
    context 'as a user' do
      it 'returns a link to contact an administrator' do
        allow(user).to receive(:can_admin_all_resources?).and_return(false)

        expect(subject).to have_text("To enable importing projects from #{import_method}, ask your GitLab administrator to configure OAuth integration")
      end
    end

    context 'as an administrator' do
      it 'returns a link to configure bitbucket' do
        allow(user).to receive(:can_admin_all_resources?).and_return(true)

        expect(subject).to have_text("To enable importing projects from #{import_method}, as administrator you need to configure OAuth integration")
      end
    end
  end

  describe '#import_from_bitbucket_message' do
    let(:import_method) { 'Bitbucket' }

    subject { helper.import_from_bitbucket_message }

    it_behaves_like 'configure import method modal'
  end

  describe '#show_inactive_project_deletion_banner?' do
    shared_examples 'does not show the banner' do |pass_project: true|
      it { expect(helper.show_inactive_project_deletion_banner?(pass_project ? project : nil)).to be(false) }
    end

    context 'with no project' do
      it_behaves_like 'does not show the banner', pass_project: false
    end

    context 'with unsaved project' do
      let_it_be(:project) { build(:project) }

      it_behaves_like 'does not show the banner'
    end

    context 'with the setting disabled' do
      before do
        stub_application_setting(delete_inactive_projects: false)
      end

      it_behaves_like 'does not show the banner'
    end

    context 'with the setting enabled' do
      before do
        stub_application_setting(delete_inactive_projects: true)
        stub_application_setting(inactive_projects_min_size_mb: 0)
        stub_application_setting(inactive_projects_send_warning_email_after_months: 1)
      end

      context 'with an active project' do
        it_behaves_like 'does not show the banner'
      end

      context 'with an inactive project' do
        before do
          project.statistics.storage_size = 1.megabyte
          project.last_activity_at = 1.year.ago
          project.save!
        end

        it 'shows the banner' do
          expect(helper.show_inactive_project_deletion_banner?(project)).to be(true)
        end
      end
    end
  end

  describe '#inactive_project_deletion_date' do
    let(:tracker) { instance_double(::Gitlab::InactiveProjectsDeletionWarningTracker) }

    before do
      stub_application_setting(inactive_projects_delete_after_months: 2)
      stub_application_setting(inactive_projects_send_warning_email_after_months: 1)

      allow(::Gitlab::InactiveProjectsDeletionWarningTracker).to receive(:new).with(project.id).and_return(tracker)
      allow(tracker).to receive(:scheduled_deletion_date).and_return('2022-03-01')
    end

    it 'returns the deletion date' do
      expect(helper.inactive_project_deletion_date(project)).to eq('2022-03-01')
    end
  end

  describe '#can_admin_associated_clusters?' do
    let_it_be_with_reload(:project) { create(:project) }

    subject { helper.send(:can_admin_associated_clusters?, project) }

    before do
      allow(helper)
        .to receive(:can?)
        .with(user, :admin_cluster, namespace)
        .and_return(user_can_admin_cluster)
    end

    context 'when project has a cluster' do
      let_it_be(:namespace) { project }

      before do
        create(:cluster, projects: [namespace])
      end

      context 'if user can admin cluster' do
        let_it_be(:user_can_admin_cluster) { true }

        it { is_expected.to be_truthy }
      end

      context 'if user can not admin cluster' do
        let_it_be(:user_can_admin_cluster) { false }

        it { is_expected.to be_falsey }
      end
    end

    context 'when project has a group cluster' do
      let_it_be(:namespace) { create(:group) }

      before do
        project.update!(namespace: namespace)
        create(:cluster, :group, groups: [namespace])
      end

      context 'if user can admin cluster' do
        let_it_be(:user_can_admin_cluster) { true }

        it { is_expected.to be_truthy }
      end

      context 'if user can not admin cluster' do
        let_it_be(:user_can_admin_cluster) { false }

        it { is_expected.to be_falsey }
      end
    end

    context 'when project doesn\'t have a cluster' do
      let_it_be(:namespace) { project }

      context 'if user can admin cluster' do
        let_it_be(:user_can_admin_cluster) { true }

        it { is_expected.to be_falsey }
      end

      context 'if user can not admin cluster' do
        let_it_be(:user_can_admin_cluster) { false }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#show_clusters_alert?' do
    using RSpec::Parameterized::TableSyntax

    subject { helper.show_clusters_alert?(project) }

    where(:is_gitlab_com, :user_can_admin_cluster, :expected) do
      false | false | false
      false | true  | false
      true  | false | false
      true  | true  | true
    end

    with_them do
      before do
        allow(::Gitlab).to receive(:com?).and_return(is_gitlab_com)
        allow(helper).to receive(:can_admin_associated_clusters?).and_return(user_can_admin_cluster)
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe '#clusters_deprecation_alert_message' do
    subject { helper.clusters_deprecation_alert_message }

    before do
      allow(helper).to receive(:has_active_license?).and_return(has_active_license)
    end

    context 'if user has an active licence' do
      let_it_be(:has_active_license) { true }

      it 'displays the correct messagee' do
        expect(subject).to eq(s_('ClusterIntegration|The certificate-based Kubernetes integration is deprecated and will be removed in the future. You should %{linkStart}migrate to the GitLab agent for Kubernetes%{linkEnd}. For more information, see the %{deprecationLinkStart}deprecation epic%{deprecationLinkEnd}, or contact GitLab support.'))
      end
    end

    context 'if user doesn\'t have an active licence' do
      let_it_be(:has_active_license) { false }

      it 'displays the correct message' do
        expect(subject).to eq(s_('ClusterIntegration|The certificate-based Kubernetes integration is deprecated and will be removed in the future. You should %{linkStart}migrate to the GitLab agent for Kubernetes%{linkEnd}. For more information, see the %{deprecationLinkStart}deprecation epic%{deprecationLinkEnd}.'))
      end
    end
  end

  describe '#project_coverage_chart_data_attributes' do
    let(:ref) { 'ref' }
    let(:daily_coverage_options) do
      {
        base_params: {
          start_date: Date.current - 90.days,
          end_date: Date.current,
          ref_path: project.repository.expand_ref(ref),
          param_type: 'coverage'
        },
        download_path: namespace_project_ci_daily_build_group_report_results_path(
          namespace_id: project.namespace,
          project_id: project,
          format: :csv
        ),
        graph_api_path: namespace_project_ci_daily_build_group_report_results_path(
          namespace_id: project.namespace,
          project_id: project,
          format: :json
        )
      }
    end

    it 'returns project data to render coverage chart' do
      expect(helper.project_coverage_chart_data_attributes(daily_coverage_options, ref)).to include(
        graph_endpoint: start_with(daily_coverage_options.fetch(:graph_api_path)),
        graph_start_date: daily_coverage_options.dig(:base_params, :start_date).strftime('%b %d'),
        graph_end_date: daily_coverage_options.dig(:base_params, :end_date).strftime('%b %d'),
        graph_ref: ref,
        graph_csv_path: start_with(daily_coverage_options.fetch(:download_path))
      )
    end
  end

  describe '#localized_project_human_access' do
    using RSpec::Parameterized::TableSyntax

    where(:key, :localized_project_human_access) do
      Gitlab::Access::NO_ACCESS           | _('No access')
      Gitlab::Access::MINIMAL_ACCESS      | _("Minimal Access")
      Gitlab::Access::GUEST               | _('Guest')
      Gitlab::Access::REPORTER            | _('Reporter')
      Gitlab::Access::DEVELOPER           | _('Developer')
      Gitlab::Access::MAINTAINER          | _('Maintainer')
      Gitlab::Access::OWNER               | _('Owner')
    end

    with_them do
      it 'with correct key' do
        expect(helper.localized_project_human_access(key)).to eq(localized_project_human_access)
      end
    end
  end

  describe '#vue_fork_divergence_data' do
    it 'returns empty hash when fork source is not available' do
      expect(helper.vue_fork_divergence_data(project, 'ref')).to eq({})
    end

    context 'when fork source is available' do
      let_it_be(:fork_network) { create(:fork_network, root_project: project_with_repo) }
      let_it_be(:source_project) { project_with_repo }

      before_all do
        project.fork_network = fork_network
        project.add_developer(user)
        source_project.add_developer(user)
      end

      it 'returns the data related to fork divergence' do
        ahead_path =
          "/#{project.full_path}/-/compare/#{source_project.default_branch}...ref?from_project_id=#{source_project.id}"
        behind_path =
          "/#{source_project.full_path}/-/compare/ref...#{source_project.default_branch}?from_project_id=#{project.id}"
        create_mr_path = "/#{project.full_path}/-/merge_requests/new?merge_request%5Bsource_branch%5D=ref&merge_request%5Btarget_branch%5D=#{source_project.default_branch}&merge_request%5Btarget_project_id%5D=#{source_project.id}"

        expect(helper.vue_fork_divergence_data(project, 'ref')).to eq({
          project_path: project.full_path,
          selected_branch: 'ref',
          source_name: source_project.full_name,
          source_path: project_path(source_project),
          can_sync_branch: 'false',
          ahead_compare_path: ahead_path,
          behind_compare_path: behind_path,
          source_default_branch: source_project.default_branch,
          create_mr_path: create_mr_path,
          view_mr_path: nil
        })
      end

      it 'returns view_mr_path if a merge request for the branch exists' do
        merge_request =
          create(:merge_request, source_project: project, target_project: project_with_repo,
            source_branch: project.default_branch, target_branch: project_with_repo.default_branch)

        expect(helper.vue_fork_divergence_data(project, project.default_branch)).to include({
          can_sync_branch: 'true',
          create_mr_path: nil,
          view_mr_path: "/#{source_project.full_path}/-/merge_requests/#{merge_request.iid}"
        })
      end

      context 'when a user cannot create a merge request' do
        using RSpec::Parameterized::TableSyntax

        where(:project_role, :source_project_role) do
          :guest | :developer
          :developer | :guest
        end

        with_them do
          it 'create_mr_path is nil' do
            project.add_member(user, project_role)
            source_project.add_member(user, source_project_role)

            expect(helper.vue_fork_divergence_data(project, 'ref')).to include({
              create_mr_path: nil, view_mr_path: nil
            })
          end
        end
      end
    end
  end

  describe '#remote_mirror_setting_enabled?' do
    it 'returns false' do
      expect(helper.remote_mirror_setting_enabled?).to be_falsy
    end
  end

  describe '#http_clone_url_to_repo' do
    before do
      allow(project).to receive(:http_url_to_repo).and_return('http_url_to_repo')
    end

    subject { helper.http_clone_url_to_repo(project) }

    it { expect(subject).to eq('http_url_to_repo') }
  end

  describe '#ssh_clone_url_to_repo' do
    before do
      allow(project).to receive(:ssh_url_to_repo).and_return('ssh_url_to_repo')
    end

    subject { helper.ssh_clone_url_to_repo(project) }

    it { expect(subject).to eq('ssh_url_to_repo') }
  end

  describe '#can_view_branch_rules?' do
    subject { helper.can_view_branch_rules? }

    context 'when user is a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it { is_expected.to be_truthy }
    end

    context 'when user is a developer' do
      before do
        project.add_developer(user)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#can_push_code?' do
    subject { helper.can_push_code? }

    context 'when user is nil' do
      let(:user) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when user is a developer on the project' do
      before do
        project.add_developer(user)
      end

      it { is_expected.to be_truthy }
    end

    context 'when user is a reporter on the project' do
      before do
        project.add_reporter(user)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#can_admin_associated_clusters?(project)' do
    using RSpec::Parameterized::TableSyntax

    where(:project_clusters_exist, :user_can_admin_project_clusters, :group_clusters_exist, :user_can_admin_group_clusters, :expected) do
      false | false | false | false | false
      true  | false | false | false | false
      false | true  | false | false | false
      false | false | true  | false | false
      false | false | false | true  | false
      true  | true  | false | false | true
      false | false | true  | true  | true
      true  | true  | true  | true  | true
    end

    with_them do
      subject { helper.can_admin_associated_clusters?(project) }

      let(:clusters) { [double('Cluster')] }
      let(:group) { double('Group') }

      before do
        allow(project)
          .to receive(:clusters)
          .and_return(project_clusters_exist ? clusters : [])
        allow(helper)
          .to receive(:can?).with(user, :admin_cluster, project)
          .and_return(user_can_admin_project_clusters)

        allow(project)
          .to receive(:group)
          .and_return(group)
        allow(group)
          .to receive(:clusters)
          .and_return(group_clusters_exist ? clusters : [])
        allow(helper)
          .to receive(:can?).with(user, :admin_cluster, project.group)
          .and_return(user_can_admin_group_clusters)
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe '#branch_rules_path' do
    subject { helper.branch_rules_path }

    it { is_expected.to eq(project_settings_repository_path(project, anchor: 'js-branch-rules')) }
  end

  describe '#visibility_level_content' do
    shared_examples 'returns visibility level content_tag' do
      let(:icon) { '<svg>fake visib level icon</svg>'.html_safe }
      let(:description) { 'Fake visib desc' }

      before do
        allow(helper).to receive(:visibility_icon_description).and_return(description)
        allow(helper).to receive(:visibility_level_icon).and_return(icon)
      end

      it 'returns visibility level content_tag' do
        expected_result = "<span class=\"has-tooltip\" data-container=\"body\" data-placement=\"top\" title=\"#{description}\">#{icon}</span>"
        expect(helper.visibility_level_content(project)).to eq(expected_result)
      end

      it 'returns visibility level content_tag with extra CSS classes' do
        expected_result = "<span class=\"has-tooltip extra-class\" data-container=\"body\" data-placement=\"top\" title=\"#{description}\">#{icon}</span>"

        expect(helper).to receive(:visibility_level_icon)
          .with(anything, options: { class: 'extra-icon-class' })
          .and_return(icon)
        result = helper.visibility_level_content(project, css_class: 'extra-class', icon_css_class: 'extra-icon-class')
        expect(result).to eq(expected_result)
      end
    end

    it_behaves_like 'returns visibility level content_tag'

    context 'when project creator is banned' do
      let(:hidden_resource_icon) { '<svg>fake hidden resource icon</svg>' }

      before do
        allow(project).to receive(:created_and_owned_by_banned_user?).and_return(true)
        allow(helper).to receive(:hidden_resource_icon).and_return(hidden_resource_icon)
      end

      it 'returns hidden resource icon' do
        expect(helper.visibility_level_content(project)).to eq hidden_resource_icon
      end
    end

    context 'with hide_projects_of_banned_users feature flag disabled' do
      before do
        stub_feature_flags(hide_projects_of_banned_users: false)
      end

      it_behaves_like 'returns visibility level content_tag'

      context 'when project creator is banned' do
        before do
          allow(project).to receive(:created_and_owned_by_banned_user?).and_return(true)
        end

        it_behaves_like 'returns visibility level content_tag'
      end
    end
  end
end

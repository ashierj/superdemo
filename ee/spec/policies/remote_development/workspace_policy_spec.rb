# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::WorkspacePolicy, feature_category: :remote_development do
  include AdminModeHelper
  using RSpec::Parameterized::TableSyntax

  let_it_be(:agent_project_creator) { create(:user) }
  let_it_be(:agent_project) { create(:project, creator: agent_project_creator) }
  let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config, project: agent_project) }
  let_it_be(:workspace_project_creator) { create(:user) }
  let_it_be(:workspace_project) { create(:project, creator: workspace_project_creator) }
  let_it_be(:workspace_owner) { create(:user) }
  let_it_be(:workspace) { create(:workspace, project: workspace_project, agent: agent, user: workspace_owner) }

  # NOTE: These need to be `let`, not `let_it_be`, otherwise fixtures are invalid (`reload: true` doesn't work either)
  let(:admin_user) { create(:admin) }
  let(:non_admin_user) { create(:user) }
  let(:user) { admin_mode ? admin_user : non_admin_user }

  subject(:policy_class) { described_class.new(user, workspace) }

  where(:admin_mode, :licensed, :workspace_owner, :role_on_workspace_project, :role_on_agent_project, :allowed) do
    # @formatter:off - Turn off RubyMine autoformatting
    # rubocop:disable Layout/LineLength -- TableSyntax should not be split across lines

    # admin_mode | # licensed | workspace_owner | role_on_workspace_project | role_on_agent_project | allowed  # check
    true         | false      | false           | :none                     | :none                 | false    # admin_mode enabled but not licensed: not allowed
    false        | false      | true            | :developer                | :none                 | false    # Workspace owner and project developer but not licensed: not allowed
    false        | true       | true            | :guest                    | :none                 | false    # Workspace owner but project guest: not allowed
    false        | false      | false           | :none                     | :maintainer           | false    # Cluster agent admin but not licensed: not allowed
    false        | true       | false           | :none                     | :developer            | false    # Not a cluster agent admin (must be maintainer): not allowed
    true         | true       | false           | :none                     | :none                 | true     # admin_mode enabled and licensed: allowed
    false        | true       | true            | :developer                | :none                 | true     # Workspace owner and project developer: allowed
    false        | true       | false           | :none                     | :maintainer           | true     # Cluster agent admin: allowed

    # @formatter:on
    # rubocop:enable Layout/LineLength
  end

  with_them do
    before do
      stub_licensed_features(remote_development: licensed)
      enable_admin_mode!(user) if admin_mode
      workspace.update!(user: user) if workspace_owner
      # rubocop:disable RSpec/BeforeAllRoleAssignment -- We don't want to do this, we want this to be reset for each example based on the TableSyntax above
      agent_project.add_role(user, role_on_agent_project) unless role_on_agent_project == :none
      workspace_project.add_role(user, role_on_workspace_project) unless role_on_workspace_project == :none
      # rubocop:enable RSpec/BeforeAllRoleAssignment

      # debug_policies(user, workspace)
    end

    # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31543
    it "has fixture sanity checks" do
      expect(agent_project.creator_id).not_to eq(workspace_project.creator_id)
      expect(agent_project.creator_id).not_to eq(user.id)
      expect(workspace_project.creator_id).not_to eq(user.id)
      expect(agent.created_by_user_id).not_to eq(workspace.user_id)
      expect(workspace.user_id).not_to eq(user.id) unless workspace_owner
    end

    # NOTE: Currently :read_workspace and :update_workspace abilities have identical rules, so we can test them with
    #       the same table checks. If their behavior diverges in the future, we'll need to duplicate the table checks.

    it { is_expected.to(allowed ? be_allowed(:read_workspace) : be_disallowed(:read_workspace)) }
    it { is_expected.to(allowed ? be_allowed(:update_workspace) : be_disallowed(:update_workspace)) }
  end

  # NOTE: Leaving this method here for future use. You can also set GITLAB_DEBUG_POLICIES=1. For more details, see:
  #       https://docs.gitlab.com/ee/development/permissions/custom_roles.html#refactoring-abilities
  def debug_policies(user, workspace)
    puts "user: #{user.username} (id: #{user.id}, admin: #{user.admin?}, " \
      "admin_mode: #{user && Gitlab::Auth::CurrentUserMode.new(user).admin_mode?})\n" # rubocop:disable Layout/LineEndStringConcatenationIndentation -- use RubyMine default formatting

    policy = RemoteDevelopment::WorkspacePolicy.new(user, workspace)
    puts "\n\nworkspace, :read_workspace"
    pp policy.debug(:read_workspace)
  end
end
